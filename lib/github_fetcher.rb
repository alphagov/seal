require "octokit"
require "yaml"
require_relative "security_alert_handler"

class GithubFetcher
  def initialize(team, dependency_prs: false)
    @organisation = ENV["SEAL_ORGANISATION"]
    @github = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
    @github.api_endpoint = ENV["GITHUB_API_ENDPOINT"] if ENV["GITHUB_API_ENDPOINT"]
    @github.auto_paginate = false
    @github.user.login
    @use_labels = team.use_labels
    @exclude_labels = team.exclude_labels.map(&:downcase).uniq
    @exclude_titles = team.exclude_titles.map(&:downcase).uniq
    @labels = {}
    @repos = team.repos
    @include_security_alerts = team.security_alerts
    @dependency_prs = dependency_prs
    @repo_security_alerts = {}
    @security_alert_handler = dependency_prs && @include_security_alerts ? SecurityAlertHandler.new(github, organisation, repos) : nil
  end

  def list_pull_requests
    fetch_all_prs(:open)
      .reject { |pr| hidden?(pr) }
      .map { |pr| present_pull_request(pr) }
      .sort_by { |pr| pr[:date] }.reverse
      .filter { |pr| @dependency_prs == (pr[:author].include?("dependabot") || pr[:branch].start_with?("renovate")) }
  rescue StandardError => e
    puts "Error listing pull requests: #{e.message}"
    []
  end

  def dependency_prs_merged_yesterday
    target_date = if Date.today.monday?
                    Date.today - 3
                  else
                    Date.today - 1
                  end

    merged_prs = fetch_all_prs(:closed).select do |pr|
      pr.merged_at &&
        pr.merged_at.to_date == target_date &&
        pr.user.login.include?("dependabot")
    end

    merged_prs_full = merged_prs.map { |pr|
      repo = pr.base.repo.name
      begin
        github.pull_request("#{organisation}/#{repo}", pr.number)
      rescue StandardError => e
        puts "Error fetching full PR #{pr.number} from #{repo}: #{e.message}"
        nil
      end
    }.compact

    total  = merged_prs_full.size
    auto   = merged_prs_full.count { |pr| pr.merged_by&.login == "govuk-ci" }
    manual = total - auto

    {
      total: total,
      auto: auto,
      manual: manual,
      auto_percentage: total.positive? ? ((auto.to_f / total) * 100).round : 0,
      manual_percentage: total.positive? ? ((manual.to_f / total) * 100).round : 0,
    }
  end

  def check_team_repos_ci
    repos.each_with_object({}) { |repo, scans_enabled| scans_enabled[repo] = has_required_scans?(repo) }
  end

  def security_alerts_count
    @security_alert_handler&.security_alerts_count
  end

  def github_api_errors
    @security_alert_handler&.github_api_errors || 0
  end

  def code_scanning_alerts_count
    @security_alert_handler&.code_scanning_alerts_count
  end

private

  attr_reader :use_labels,
              :security_alerts,
              :exclude_labels,
              :exclude_titles,
              :repos,
              :organisation,
              :github

  def fetch_all_prs(state)
    repos.flat_map do |repo|
      @repo_security_alerts[repo] = @security_alert_handler.filter_security_alerts(repo) if @security_alert_handler

      prs = github.pull_requests(
        "#{organisation}/#{repo}",
        state: state,
        sort: :updated,
        direction: :desc,
        per_page: 50,
      )

      prs.reject(&:draft)
    rescue StandardError => e
      puts "Error fetching #{state} pull requests from GitHub for repo #{repo}: #{e.message}"
      []
    end
  end

  def present_pull_request(pull_request)
    repo = pull_request.base.repo.name
    security_label = @dependency_prs && @include_security_alerts ? @security_alert_handler.label_for_branch(pull_request.head.ref, pull_request.title, @repo_security_alerts[repo]) : nil

    {
      title: pull_request.title,
      link: pull_request.html_url,
      author: pull_request.user.login,
      repo:,
      branch: pull_request.head.ref,
      comments_count: count_comments(pull_request, repo),
      thumbs_up: count_thumbs_up(pull_request, repo),
      approved: approved?(pull_request, repo),
      updated: Date.parse(pull_request.updated_at.to_s),
      created: Date.parse(pull_request.created_at.to_s),
      marked_ready_for_review_at: marked_ready_for_review_at(pull_request, repo)&.to_date,
      labels: labels(pull_request),
      security_label:,
    }
  rescue StandardError => e
    puts "Error presenting pull request #{pull_request.html_url}: #{e.message}"
    {}
  end

  def count_comments(pull_request, repo)
    pr = github.pull_request("#{organisation}/#{repo}", pull_request.number)
    pr.review_comments + pr.comments
  rescue StandardError => e
    puts "Error counting comments for PR #{pull_request.html_url}: #{e.message}"
    0
  end

  def count_thumbs_up(pull_request, repo)
    response = github.issue_comments("#{organisation}/#{repo}", pull_request.number)
    comments_string = response.map(&:body).join
    comments_string.scan(/:\+1:/).count
  rescue StandardError => e
    puts "Error counting thumbs up for PR #{pull_request.html_url}: #{e.message}"
    0
  end

  def approved?(pull_request, repo)
    reviews = github.get("repos/#{organisation}/#{repo}/pulls/#{pull_request.number}/reviews")
    reviews.any? { |review| review.state == "APPROVED" }
  rescue StandardError => e
    puts "Error checking approval for PR #{pull_request.html_url}: #{e.message}"
    false
  end

  def labels(pull_request)
    return [] unless use_labels

    pull_request.labels.map { |label| label[:name].downcase }
  rescue StandardError => e
    puts "Error fetching labels for PR #{pull_request.html_url}: #{e.message}"
    []
  end

  def hidden?(pull_request)
    excluded_label?(pull_request) || excluded_title?(pull_request.title)
  rescue StandardError => e
    puts "Error checking hidden status for PR #{pull_request.html_url}: #{e.message}"
    false
  end

  def excluded_label?(pull_request)
    exclude_labels.any? { |e| labels(pull_request).include?(e) }
  end

  def excluded_title?(title)
    exclude_titles.any? { |t| title.downcase.include?(t) }
  end

  def marked_ready_for_review_at(pull_request, repo)
    events = github.get("repos/#{organisation}/#{repo}/issues/#{pull_request.number}/timeline")
    events.filter { |e| e.event == "ready_for_review" }.map(&:created_at).max
  rescue StandardError => e
    puts "Error fetching marked ready for review time for PR #{pull_request.html_url}: #{e.message}"
    nil
  end

  def ignored_ci_repos
    YAML.load_file(File.join(File.dirname(__FILE__), "../ignored_ci_repos.yml"))
  end

  def rails_app?(repo)
    gemfile = github.contents("#{organisation}/#{repo}", path: "Gemfile")
    gemfile.content.unpack1("m").include?("\ngem \"rails\"")
  rescue Octokit::NotFound
    false
  end

  def fetch_workflows(repo)
    ci_yml = fetch_file_content(repo, ".github/workflows/ci.yml")
    security_yml = fetch_file_content(repo, ".github/workflows/security.yml")

    return nil if ci_yml.nil? && security_yml.nil?

    { ci: ci_yml, security: security_yml }
  end

  def fetch_file_content(repo, path)
    github.contents("#{organisation}/#{repo}", path:).content.unpack1("m")
  rescue Octokit::NotFound
    nil
  end

  def has_required_scans?(repo)
    return true if ignored_ci_repos.include?(repo)

    workflows = fetch_workflows(repo)
    return true if workflows.nil? # if workflows are not present assume no scans are needed

    scans_needed = rails_app?(repo) ? %i[sca sast brakeman] : %i[sca sast]
    scans_needed.all? do |scan_type|
      workflows.values.any? { |workflow| has_scan?(workflow, scan_type) }
    end
  end

  def has_scan?(workflow, scan_type)
    return false if workflow.nil?

    case scan_type
    when :sca
      workflow.include?("uses: alphagov/govuk-infrastructure/.github/workflows/dependency-review.yml@main")
    when :sast
      workflow.include?("uses: alphagov/govuk-infrastructure/.github/workflows/codeql-analysis.yml@main")
    when :brakeman
      workflow.include?("uses: alphagov/govuk-infrastructure/.github/workflows/brakeman.yml@main") ||
        workflow.include?("bundle exec brakeman")
    end
  end
end

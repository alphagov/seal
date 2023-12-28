require "octokit"
require "yaml"
require_relative "security_alert_handler"

class GithubFetcher
  def initialize(team, dependabot_prs_only: false)
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
    @dependabot_prs_only = dependabot_prs_only
    @repo_security_alerts = {}
    @security_alert_handler = dependabot_prs_only && @include_security_alerts ? SecurityAlertHandler.new(github, organisation, repos) : nil
  end

  def list_pull_requests
    pull_requests_from_github
      .reject { |pr| hidden?(pr) }
      .map { |pr| present_pull_request(pr) }
      .sort_by { |pr| pr[:date] }.reverse
      .filter { |pr| @dependabot_prs_only == pr[:author].include?("dependabot") }
  rescue StandardError => e
    puts "Error listing pull requests: #{e.message}"
    []
  end

  def pull_requests_from_github
    repos.flat_map do |repo|
      @repo_security_alerts[repo] = @security_alert_handler.filter_security_alerts(repo) if @security_alert_handler
      fetch_pull_requests(repo).reject(&:draft)
    end
  end

  def check_team_repos_ci
    repos.each_with_object({}) { |repo, sca_sast_enabled| sca_sast_enabled[repo] = has_sca_sast_scans?(repo) }
  end

  def security_alerts_count
    @security_alert_handler&.security_alerts_count
  end

  def github_api_errors
    @security_alert_handler&.github_api_errors || 0
  end

private

  attr_reader :use_labels,
              :security_alerts,
              :exclude_labels,
              :exclude_titles,
              :repos,
              :organisation,
              :github

  def fetch_pull_requests(repo)
    github.pull_requests("#{organisation}/#{repo}", state: :open, sort: :created)
  rescue StandardError => e
    puts "Error fetching pull requests from GitHub for repo #{repo}: #{e.message}"
    []
  end

  def present_pull_request(pull_request)
    repo = pull_request.base.repo.name
    security_label = @dependabot_prs_only && @include_security_alerts ? @security_alert_handler.label_for_branch(pull_request.head.ref, pull_request.title, @repo_security_alerts[repo]) : nil

    {
      title: pull_request.title,
      link: pull_request.html_url,
      author: pull_request.user.login,
      repo:,
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

  def has_sca_sast_scans?(repo)
    return true if ignored_ci_repos.include?(repo)

    ci_file = Base64.decode64(github.contents("#{organisation}/#{repo}", path: ".github/workflows/ci.yml").content)
    sca_string = "uses: alphagov/govuk-infrastructure/.github/workflows/dependency-review.yml@main"
    sast_string = "uses: alphagov/govuk-infrastructure/.github/workflows/codeql-analysis.yml@main"
    snyk_string = "uses: alphagov/govuk-infrastructure/.github/workflows/snyk-security.yml@main"

    ci_file.include?(sca_string) && ci_file.include?(sast_string) && ci_file.include?(snyk_string)
  rescue Octokit::NotFound => e
    true # if a CI file is not present assume no scans are needed
  end
end

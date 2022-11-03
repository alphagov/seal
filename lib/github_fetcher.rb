require "octokit"

class GithubFetcher
  def initialize(team)
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
  end

  def list_pull_requests
    pull_requests_from_github
      .reject { |pr| hidden?(pr) }
      .map { |pr| present_pull_request(pr) }
      .sort_by { |pr| pr[:date] }.reverse
  end

  def pull_requests_from_github
    pulls = []
    @repos.each do |repo|
      github.pull_requests("#{organisation}/#{repo}", { state: :open, sort: :created })
            .reject { |p| p.user.login.include?("dependabot") || p.draft }.each do |pr|
        pulls << pr
      end
    rescue StandardError => e
      puts e.message
      next
    end

    pulls.flatten
  end

private

  attr_reader :use_labels,
              :exclude_labels,
              :exclude_titles,
              :repos,
              :organisation,
              :github

  def present_pull_request(pull_request)
    repo = pull_request.base.repo.name

    {
      title: pull_request.title,
      link: pull_request.html_url,
      author: pull_request.user.login,
      repo:,
      comments_count: count_comments(pull_request, repo),
      thumbs_up: count_thumbs_up(pull_request, repo),
      approved: approved?(pull_request, repo),
      updated: Date.parse(pull_request.updated_at.to_s),
      labels: labels(pull_request),
    }
  end

  def count_comments(pull_request, repo)
    pr = github.pull_request("#{organisation}/#{repo}", pull_request.number)
    pr.review_comments + pr.comments
  end

  def count_thumbs_up(pull_request, repo)
    response = github.issue_comments("#{organisation}/#{repo}", pull_request.number)
    comments_string = response.map(&:body).join
    comments_string.scan(/:\+1:/).count
  end

  def approved?(pull_request, repo)
    reviews = github.get("repos/#{organisation}/#{repo}/pulls/#{pull_request.number}/reviews")
    reviews.any? { |review| review.state == "APPROVED" }
  end

  def labels(pull_request)
    return [] unless use_labels

    pull_request.labels.map { |label| label[:name].downcase }
  end

  def hidden?(pull_request)
    excluded_label?(pull_request) || excluded_title?(pull_request.title)
  end

  def excluded_label?(pull_request)
    exclude_labels.any? { |e| labels(pull_request).include?(e) }
  end

  def excluded_title?(title)
    exclude_titles.any? { |t| title.downcase.include?(t) }
  end
end

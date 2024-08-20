require "json"
require "octokit"
require "open-uri"
require "yaml"

class ValidateRepos
  def initialize
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN"))
  end

  def github_repos_tagged_govuk
    @github_repos_tagged_govuk ||= repos.map { |repo| repo["name"] }
  end

  def govuk_repo_names
    @govuk_repo_names ||= JSON.parse(Net::HTTP.get_response(URI.parse("https://docs.publishing.service.gov.uk/repos.json")).body)
      .map { |repo| repo["app_name"] }
      .reject { |app| ignored_apps.include?(app) }
  end

  def untagged_repos
    (govuk_repo_names - github_repos_tagged_govuk).join("\n")
  end

  def falsely_tagged_repos
    (github_repos_tagged_govuk - govuk_repo_names).join("\n")
  end

  def repos
    @client
      .org_repos("alphagov", accept: "application/vnd.github.mercy-preview+json")
      .select { |repo| repo.topics.to_a.include?("govuk") }
      .reject(&:archived)
      .reject { |repo| ignored_repos.include?(repo.full_name) }
      .sort_by { |repo| repo[:full_name] }
  end

  def ignored_repos
    ["alphagov/licensify"] # Licensify consists of 3 apps in 1 repo
  end

  def ignored_apps
    %w[licensify-backend]
  end
end

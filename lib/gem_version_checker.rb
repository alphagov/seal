require "uri"
require "net/http"
require "json"
require "octokit"
require_relative "slack_poster"

class GemVersionChecker
  GEMS_API_URI = URI("https://docs.publishing.service.gov.uk/gems.json")

  def print_version_discrepancies
    all_govuk_gems.group_by { |gem| gem["team"] }.each do |team, gems|
      message = build_message(gems)
      puts "team: #{team}\n#{message}"

      poster = SlackPoster.new(team.to_s, "gem")
      poster.send_request(message.to_s) unless message.empty?
    end
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end

  def build_message(gems)
    gems.filter_map { |gem|
      repo_name = gem["app_name"]
      repo_url = gem["links"]["repo_url"]
      rubygems_version = fetch_rubygems_version(repo_name)
      if rubygems_version && change_is_significant?(repo_name, rubygems_version)
        "<#{repo_url}|#{repo_name}> has unreleased changes since v#{rubygems_version}"
      end
    }.join("\n")
  end

  def all_govuk_gems
    res = Net::HTTP.get_response(GEMS_API_URI)
    raise "HTTP request failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def fetch_rubygems_version(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    res = Net::HTTP.get_response(uri)
    raise "Failed to fetch gem version: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)["version"]
  rescue StandardError => e
    puts "An error occurred while fetching gem version: #{e.message}"
    nil
  end

  def files_changed_since_tag(repo, tag)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        if system("git clone --recursive --depth 1 --shallow-submodules --no-single-branch https://github.com/alphagov/#{repo}.git > /dev/null 2>&1")
          Dir.chdir(repo) do
            `git diff --name-only #{tag}`.split("\n")
          end
        else
          puts "Warning: Failed to clone #{repo}"
          []
        end
      end
    end
  end

  def change_is_significant?(repo_name, previous_version)
    files_changed_since_tag(repo_name, "v#{previous_version}").any? do |path|
      path.start_with?("app/", "lib/") || path == "CHANGELOG.md"
    end
  end
end

require "uri"
require "net/http"
require "json"

class GemVersionChecker
  def detect_version_discrepancies(gem_name)
    rubygems_version = fetch_rubygems_version(gem_name)
    rubygems_version if rubygems_version && change_is_significant?(gem_name, rubygems_version)
  end

  def fetch_rubygems_version(gem_name)
    uri = URI("https://rubygems.org/api/v1/gems/#{gem_name}.json")
    res = Net::HTTP.get_response(uri)

    JSON.parse(res.body)["version"] if res.is_a?(Net::HTTPSuccess)
  end

  def files_changed_since_tag(repo, tag)
    Dir.mktmpdir do |path|
      Dir.chdir(path) do
        if system("git clone --recursive --depth 1 --shallow-submodules --no-single-branch https://github.com/alphagov/#{repo}.git > /dev/null 2>&1")
          Dir.chdir(repo) { `git diff --name-only #{tag}`.split("\n") }
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

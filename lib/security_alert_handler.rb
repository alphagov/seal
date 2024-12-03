class SecurityAlertHandler
  attr_reader :github_api_errors

  def initialize(github, organisation, repos)
    @github = github
    @organisation = organisation
    @repos = repos
    @github_api_errors = 0
    @global_security_alerts = fetch_security_alerts
  end

  def security_alerts_count
    @global_security_alerts.length
  end

  def filter_security_alerts(repo)
    @global_security_alerts.select { |alert| alert[:repo] == repo }
  end

  def label_for_branch(branch, title, alerts_for_repo)
    security_label_for_branch(branch, title, alerts_for_repo)
  end

private

  def fetch_security_alerts
    alerts = []
    @repos.each do |repo|
      response = @github.get("https://api.github.com/repos/#{@organisation}/#{repo}/dependabot/alerts", accept: "application/vnd.github+json", state: "open")
      alerts.concat(response.map { |alert| parse_security_alert(alert, repo) })
    rescue StandardError => e
      @github_api_errors += 1
      puts "Error fetching security alerts for repo #{repo}: #{e.message}"
      next
    end
    alerts
  end

  def parse_security_alert(alert, repo)
    {
      repo:,
      package_manager: alert[:dependency][:package][:ecosystem],
      dependency_name: alert[:dependency][:package][:name],
      vulnerable_version_ranges: alert[:security_vulnerability][:vulnerable_version_range].split(", ").map(&:strip),
      url: alert[:html_url],
      severity: alert[:security_vulnerability][:severity],
    }
  end

  def extract_versions_from_title(title)
    match = title.match(/Bump (?<dependency_name>[\w-]+) from (?<old_version>[\d.]+) to (?<new_version>[\d.]+)/)
    return nil unless match

    {
      old_version: match[:old_version],
      new_version: match[:new_version],
    }
  end

  def version_in_range?(version, vulnerable_version_range)
    Gem::Requirement.new(vulnerable_version_range).satisfied_by?(Gem::Version.new(version))
  end

  def security_label_for_branch(branch, title, alerts)
    match = branch.match(%r{dependabot/(?<package_manager>[^/]+)/(?<dependency_name>[^/]+)-(?<version>[\d.]+)})
    return nil unless match

    dependency_name = match[:dependency_name]

    versions = extract_versions_from_title(title)
    return nil unless versions

    solvable_alerts = find_solvable_alerts(dependency_name, versions[:old_version], versions[:new_version], alerts)

    return nil if solvable_alerts.empty?

    {
      url: "https://github.com/#{@organisation}/#{solvable_alerts.first[:repo]}/security/dependabot?q=package:#{solvable_alerts.first[:dependency_name]}+is:open",
      severity: solvable_alerts.map { |a| a[:severity] }.max_by { |s| severity_score(s) },
      count: solvable_alerts.count,
    }
  end

  def find_solvable_alerts(dependency_name, old_version, new_version, alerts)
    alerts.select do |alert|
      alert[:dependency_name] == dependency_name &&
        version_in_range?(old_version, alert[:vulnerable_version_ranges]) &&
        !version_in_range?(new_version, alert[:vulnerable_version_ranges])
    end
  end

  def severity_score(severity)
    severity_mapping = { "low" => 1, "medium" => 2, "high" => 3, "critical" => 4 }
    severity_mapping[severity] || 0
  end
end

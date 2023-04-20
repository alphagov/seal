require "yaml"

require_relative "team"

class TeamBuilder
  def self.build(env: {}, team_name: nil)
    new(env).build(team_name)
  end

  def initialize(env)
    @env = env
    @govuk_data = govuk_json
  end

  def build(team_name = nil)
    if team_name && !team_name.empty?
      build_single_team(team_name)
    else
      build_all_teams
    end
  rescue StandardError => e
    puts "Error building team(s): #{e.message}"
    []
  end

private

  attr_reader :env

  def build_single_team(team_name)
    team = Team.new(**apply_env(static_config[team_name.to_s] || {}))

    if team.channel.nil?
      []
    else
      if team.repos.empty?
        (team.repos << govuk_team_repos(team.channel)).flatten!
      end
      [team]
    end
  rescue StandardError => e
    puts "Error building single team (#{team_name}): #{e.message}"
    []
  end

  def build_all_teams
    static_config.map do |_, team_config|
      if team_config["repos"].nil?
        team_config["repos"] = govuk_team_repos(team_config["channel"])
      end
      Team.new(**apply_env(team_config))
    end
  rescue StandardError => e
    puts "Error building all teams: #{e.message}"
    []
  end

  def apply_env(config)
    {
      use_labels: env["GITHUB_USE_LABELS"] == "true" || config["use_labels"],
      quotes_days: env["GITHUB_QUOTES_DAYS"]&.split(",") || config["quotes_days"],
      security_alerts: env["GITHUB_SECURITY_ALERTS"] == "true" || config["security_alerts"],
      compact: env["COMPACT"] == "true" || config["compact"],
      exclude_labels: env["GITHUB_EXCLUDE_LABELS"]&.split(",") || config["exclude_labels"],
      exclude_titles: env["GITHUB_EXCLUDE_TITLES"]&.split(",") || config["exclude_titles"],
      repos: env["GITHUB_REPOS"]&.split(",") || config["repos"],
      quotes: env["SEAL_QUOTES"]&.split(",") || config["quotes"],
      slack_channel: env["SLACK_CHANNEL"] || config["channel"],
    }
  end

  def static_config
    @static_config ||= begin
      filename = File.join(File.dirname(__FILE__), "../config/#{env['SEAL_ORGANISATION']}.yml")

      if File.exist?(filename)
        YAML.load_file(filename, aliases: true)
      else
        {}
      end
    end
  rescue StandardError => e
    puts "Error loading static configuration: #{e.message}"
    {}
  end

  def govuk_json
    source = "https://docs.publishing.service.gov.uk/repos.json"
    resp = Net::HTTP.get_response(URI.parse(source))
    JSON.parse(resp.body)
  rescue StandardError => e
    puts "Error fetching govuk JSON: #{e.message}"
    []
  end

  def govuk_team_repos(team_channel)
    @govuk_data.select { |repos| repos["team"] == team_channel }.map { |repo| repo["app_name"] }
  rescue StandardError => e
    puts "Error fetching govuk team repos (#{team_channel}): #{e.message}"
    []
  end
end

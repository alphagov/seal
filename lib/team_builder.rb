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
  end

private

  attr_reader :env

  def build_single_team(team_name)
    team = Team.new(**apply_env(static_config[team_name.to_s] || {}))

    if team.channel.nil?
      []
    else
      (team.repos << govuk_team_repos(team.channel)).flatten! if team.repos.empty?
      [team]
    end
  rescue StandardError => e
    puts "Error building single team (#{team_name}): #{e.message}"
    []
  end

  def build_all_teams
    static_config.map do |team_name, team_config|
      if team_config["repos"].nil?
        team_config["repos"] = govuk_team_repos(team_config["channel"])
      elsif is_govuk_team?(team_name)
        raise "#{team_name} is a GOV.UK team and shouldn't list repos in ./config/alphagov.yml"
      end
      team_config["ci_checks"] = is_govuk_team?(team_name)
      team_config["gems"] = is_govuk_team?(team_name)
      Team.new(**apply_env(team_config))
    end
  end

  def apply_env(config)
    {
      use_labels: env["GITHUB_USE_LABELS"] == "true" || config["use_labels"],
      quotes_days: env["GITHUB_QUOTES_DAYS"]&.split(",") || config["quotes_days"],
      security_alerts: env["GITHUB_SECURITY_ALERTS"] == "true" || config["security_alerts"],
      morning_seal_quotes: env["MORNING_SEAL_QUOTES"] == "true" || config["morning_seal_quotes"],
      seal_prs: env["SEAL_PRS"] == "true" || config["seal_prs"],
      afternoon_seal_quotes: env["AFTERNOON_SEAL_QUOTES"] == "true" || config["afternoon_seal_quotes"],
      dependapanda: env["DEPENDAPANDA"] == "true" || config["dependapanda"],
      ci_checks: env["CI_CHECKS"] == "true" || config["ci_checks"],
      gems: env["GEMS"] == "true" || config["gems"],
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
    @govuk_data.select { |repos| repos["alerts_team"] == team_channel }.map { |repo| repo["app_name"] }
  rescue StandardError => e
    puts "Error fetching govuk team repos (#{team_channel}): #{e.message}"
    []
  end

  def is_govuk_team?(team)
    @govuk_data.any? { |repo| repo["alerts_team"] == "##{team}" }
  end
end

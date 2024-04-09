class SlackPoster
  attr_accessor :webhook_url, :poster, :mood, :season_name

  def initialize(team_channel, mood)
    @webhook_url = ENV["SLACK_WEBHOOK"]
    @team_channel = team_channel
    @mood = mood
    @today = Date.today
    mood_hash
    channel
    create_poster
  end

  def create_poster
    @poster = Slack::Poster.new(webhook_url.to_s, slack_options)
  end

  def send_request(message)
    if ENV["DRY"]
      puts "Will post #{mood} message to #{channel} on #{today.strftime('%A')}"
      puts slack_options.inspect
      puts message
    else
      poster.send_message(message)
    end
  rescue StandardError => e
    puts "Error sending request: #{e.message}"
  end

private

  attr_reader :today

  def slack_options
    {
      icon_emoji: @mood_hash[:icon_emoji],
      username: @mood_hash[:username],
      channel: @team_channel,
    }
  end

  def mood_hash
    @mood_hash = {}
    check_season
    set_mood_from_team
    assign_poster_settings
    @mood_hash
  end

  def assign_poster_settings
    @mood_hash[:icon_emoji], @mood_hash[:username] =
      case @mood
      when "panda"
        [":panda_face:", "Dependapanda"]
      when "informative"
        [":#{@season_symbol}informative_seal:", "#{@season_name}Informative Seal"]
      when "approval"
        [":#{@season_symbol}seal_of_approval:", "#{@season_name}Seal of Approval"]
      when "angry"
        [":#{@season_symbol}angrier_seal:", "#{@season_name}Angry Seal"]
      when "robot_face"
        [":robot_face:", "Angry CI Robot"]
      when "tea"
        [":manatea:", "Tea Seal"]
      when "charter"
        [":happyseal:", "Team Charter Seal"]
      when "fun-workstream"
        [":wholesome-seal:", "It's ok Seal"]
      when "govuk-green-team"
        [":happybabyseal:", "Elephant Seal"]
      else
        raise "Bad mood: #{mood}."
      end
  end

  def check_season
    @season_name = case [today.day, today.month]
                   in [23..31, 10]
                     "Halloween "
                   in [1, 1] | [1..31, 12]
                     "Festive Season "
                   else
                     ""
                   end
    @season_symbol = snake_case(@season_name)
  end

  def snake_case(string)
    string.downcase.gsub(" ", "_")
  end

  def set_mood_from_team
    @mood = case @team_channel
            when "#club-tea"
              "tea"
            when "#govuk", "#gds-community", "#sealtesting"
              "fun-workstream"
            when "#govuk-green-team"
              "govuk-green-team"
            else
              @mood.nil? ? "charter" : @mood
            end
  end

  def channel
    @team_channel = "#bot-testing" if ENV["DEVELOPMENT"]
  end
end

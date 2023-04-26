class SlackPoster
  attr_accessor :webhook_url, :poster, :mood, :mood_hash, :channel, :season_name, :halloween_season, :festive_season

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
    check_if_quotes
    assign_poster_settings
  end

  def assign_poster_settings
    case @mood
    when "panda"
      @mood_hash[:icon_emoji] = ":panda_face:"
      @mood_hash[:username] = "Dependapanda"
    when "informative"
      @mood_hash[:icon_emoji] = ":#{@season_symbol}informative_seal:"
      @mood_hash[:username] = "#{@season_name}Informative Seal"
    when "approval"
      @mood_hash[:icon_emoji] = ":#{@season_symbol}seal_of_approval:"
      @mood_hash[:username] = "#{@season_name}Seal of Approval"
    when "angry"
      @mood_hash[:icon_emoji] = ":#{@season_symbol}angrier_seal:"
      @mood_hash[:username] = "#{@season_name}Angry Seal"
    when "tea"
      @mood_hash[:icon_emoji] = ":manatea:"
      @mood_hash[:username] = "Tea Seal"
    when "charter"
      @mood_hash[:icon_emoji] = ":happyseal:"
      @mood_hash[:username] = "Team Charter Seal"
    when "fun-workstream"
      @mood_hash[:icon_emoji] = ":wholesome-seal:"
      @mood_hash[:username] = "It's ok Seal"
    when "govuk-green-team"
      @mood_hash[:icon_emoji] = ":happybabyseal:"
      @mood_hash[:username] = "Elephant Seal"
    else
      raise "Bad mood: #{mood}."
    end
  end

  def check_season
    @season_name = if halloween_season?
                     "Halloween "
                   elsif festive_season?
                     "Festive Season "
                   else
                     ""
                   end
    @season_symbol = snake_case(@season_name)
  end

  def halloween_season?
    this_year = today.year
    today <= Date.new(this_year, 10, 31) && today >= Date.new(this_year, 10, 23)
  end

  def festive_season?
    this_year = today.year
    return true if today <= Date.new(this_year, 12, 31) && today >= Date.new(this_year, 12, 1)

    today == Date.new(this_year, 1, 1)
  end

  def snake_case(string)
    string.downcase.gsub(" ", "_")
  end

  def check_if_quotes
    if @team_channel == "#club-tea"
      @mood = "tea"
    # If the channel name is either govuk or gds-community, set the mood to 'fun-workstream'
    elsif ["#govuk", "#gds-community", "#sealtesting"].include?(@team_channel)
      @mood = "fun-workstream"
    elsif @team_channel == "#govuk-green-team"
      @mood = "govuk-green-team"
    elsif @mood.nil?
      @mood = "charter"
    end
  end

  def channel
    @team_channel = "#bot-testing" if ENV["DYNO"].nil?
  end
end

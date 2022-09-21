class Team
  def initialize(
    use_labels: nil,
    compact: nil,
    exclude_labels: nil,
    exclude_titles: nil,
    repos: nil,
    quotes: nil,
    slack_channel: nil
  )
    @use_labels = (use_labels.nil? ? false : use_labels)
    @compact = (compact.nil? ? false : compact)
    @exclude_labels = exclude_labels || []
    @exclude_titles = exclude_titles || []
    @repos = repos || []
    @quotes = quotes || []
    @channel = slack_channel
  end

  attr_reader(*%i[
    use_labels
    compact
    exclude_labels
    exclude_titles
    repos
    quotes
    channel
  ])
end

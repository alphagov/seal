require "pathname"
require_relative "github_fetcher"
require_relative "message"

class MessageBuilder
  TEMPLATE_DIR = Pathname.new(File.join(File.dirname(__FILE__), *%w[.. templates]))

  attr_accessor :pull_requests, :report, :mood, :poster_mood

  def initialize(team, animal)
    @team = team
    @animal = animal
  end

  def build
    case @animal
    when :panda
      build_dependapanda_message
    else
      build_regular_message
    end
  rescue StandardError => e
    puts "Error building message: #{e.message}"
    nil
  end

  def rotten?(pull_request)
    today = Date.today
    actual_age = (today - pr_date(pull_request)).to_i
    weekdays_age = if today.monday?
                     actual_age - 2
                   elsif today.tuesday?
                     actual_age - 1
                   else
                     actual_age
                   end
    weekdays_age > 2
  end

private

  attr_reader :team

  def build_dependapanda_message
    return unless pull_requests.any?

    Message.new(dependapanda_message, mood: "panda")
  end

  def build_regular_message
    if old_pull_requests.any?
      Message.new(bark_about_old_pull_requests, mood: "angry")
    elsif unapproved_pull_requests.any?
      Message.new(list_pull_requests, mood: "informative")
    else
      Message.new(no_pull_requests, mood: "approval")
    end
  end

  def pr_date(pr)
    pr[:marked_ready_for_review_at] || pr[:created]
  end

  def github_fetcher
    @github_fetcher ||= GithubFetcher.new(team, dependabot_prs_only: @animal == :panda)
  end

  def pull_requests
    @pull_requests ||= github_fetcher.list_pull_requests
  end

  def old_pull_requests
    @old_pull_requests ||= pull_requests.select { |pr| rotten?(pr) }
  end

  def unapproved_pull_requests
    @unapproved_pull_requests ||= pull_requests.reject { |pr| pr[:approved] }
  end

  def recent_pull_requests
    @recent_pull_requests ||= unapproved_pull_requests - old_pull_requests
  end

  def bark_about_old_pull_requests
    @angry_bark = present_multiple(old_pull_requests)
    @list_recent_pull_requests = present_multiple(recent_pull_requests)

    render "old_pull_requests"
  end

  def list_pull_requests
    @message = present_multiple(unapproved_pull_requests)

    render "list_pull_requests"
  end

  def no_pull_requests
    render "no_pull_requests"
  end

  def dependapanda_message
    @repos = panda_presenter

    @all_prs_count = @repos.sum { |repo| repo[:pr_count] }

    if @team.security_alerts
      @all_alerts_count = github_fetcher.security_alerts_count
      @all_alerts_link = "https://github.com/orgs/govuk-one-login/security/alerts/dependabot?q=is:open+repo:#{@team.repos.join(',')}"
      @github_api_errors = github_fetcher.github_api_errors

      security_prs = @repos.flat_map { |repo| repo[:security_prs] }

      severity_mapping = { "low" => 1, "medium" => 2, "high" => 3, "critical" => 4 }

      @security_prs_ordered = security_prs.sort_by { |pr| [severity_mapping[pr[:security_label][:severity]], pr[:security_label][:count]] }
        .map { |pr| pr.merge(pr_link: pr[:link], pr_title: pr[:title]) }.reverse
    end

    template_file = TEMPLATE_DIR + "dependapanda.text.erb"
    ERB.new(template_file.read, trim_mode: '-').result(binding).strip
  end

  def comments(pull_request)
    return " comment" if pull_request[:comments_count] == 1

    " comments"
  end

  def these(item_count)
    if item_count == 1
      "This"
    else
      "These"
    end
  end

  def pr_plural(pr_count)
    if pr_count == 1
      "pull request is"
    else
      "pull requests are"
    end
  end

  def present(pr, index)
    @index = index
    @pr = pr
    @title = pr[:title]
    @days = age_in_days(pr_date(@pr))

    @thumbs_up = if (@pr[:thumbs_up]).positive?
                   " | #{@pr[:thumbs_up]} :+1:"
                 else
                   ""
                 end

    @approved = @pr[:approved] ? " | :white_check_mark: " : ""

    render "_pull_request"
  end

  def present_multiple(prs)
    prs.map.with_index(1) { |pr, n| present(pr, n) }.join("\n")
  end

  def age_in_days(date)
    (Date.today - date).to_i
  end

  def days_plural(days)
    case days
    when 0
      "today"
    when 1
      "yesterday"
    else
      "#{days} days ago"
    end
  end

  def labels(pull_request)
    pull_request[:labels]
      .map { |label| "[#{label['name']}]" }
      .join(" ")
  end

  def html_encode(string)
    string.tr("&", "&amp;").tr("<", "&lt;").tr(">", "&gt;")
  end

  def apply_style(template_name)
    if team.compact
      "#{template_name}.compact"
    else
      template_name
    end
  end

  def render(template_name)
    template_file = TEMPLATE_DIR + "#{apply_style(template_name)}.text.erb"
    ERB.new(template_file.read).result(binding).strip
  end

  def panda_presenter
    prs_by_repo = pull_requests.group_by { |pr| pr[:repo] }

    prs = prs_by_repo.map do |repo_name, prs_for_app|
      oldest_pr, newest_pr = prs_for_app.map { |pr| pr_date(pr) }.minmax
      security_prs = @team.security_alerts ? prs_for_app.select { |pr| pr[:security_label] } : []

      {
        repo_name:,
        repo_url: "https://github.com/govuk-one-login/#{repo_name}/pulls?q=is:pr+is:open+label:dependencies",
        pr_count: prs_for_app.count,
        oldest_pr: age_in_days(oldest_pr),
        newest_pr: age_in_days(newest_pr),
        security_prs:,
      }
    end

    prs.sort_by { |pr| pr[:oldest_pr] }.reverse
  rescue StandardError => e
    puts "Error generating panda presenter: #{e.message}"
    []
  end
end

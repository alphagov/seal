#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require(:default)

require_relative "bank_holidays"
require_relative "message_builder"
require_relative "slack_poster"

# Entry point for the Seal!
class Seal
  def initialize(teams)
    @teams = teams
  end

  def bark(mode: nil)
    return if Date.today.bank_holiday?

    teams.each do |team|
      bark_at(team, mode:)
    end
  end

private

  attr_reader :teams

  def bark_at(team, mode: nil)
    message = case mode
              when "morning_seal_quotes", "afternoon_seal_quotes"
                send_quotes_message(team, mode)
              when "dependapanda"
                if team.dependapanda
                  sleep 60 # to prevent rate-limiting
                  MessageBuilder.new(team, :panda).build
                end
              when "ci"
                MessageBuilder.new(team, :ci).build if team.ci_checks
              when "seal_prs"
                MessageBuilder.new(team, :seal).build if team.seal_prs
              when "gems"
                MessageBuilder.new(team, :gems).build if team.gems
              end

    return if message.nil? || message.text.nil?

    poster = SlackPoster.new(team.channel, message.mood)
    poster.send_request(message.text)
  rescue StandardError => e
    puts "Error barking at team '#{team.name}': #{e.message}"
  end

  def send_quotes_message(team, mode)
    today_is_quote_day = team.quotes_days.map(&:downcase).include?(Date.today.strftime("%A").downcase)
    team_has_enabled_this_mode = team.public_send(mode.to_s)

    Message.new(team.quotes.sample) if today_is_quote_day && team_has_enabled_this_mode
  end
end

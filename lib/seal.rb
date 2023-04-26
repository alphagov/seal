#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require(:default)

require_relative "message_builder"
require_relative "slack_poster"

# Entry point for the Seal!
class Seal
  def initialize(teams)
    @teams = teams
  end

  def bark(mode: nil)
    teams.each do |team|
      bark_at(team, mode:)
    end
  end

private

  attr_reader :teams

  def bark_at(team, mode: nil)
    message = case mode
              when "quotes"
                Message.new(team.quotes.sample) if team.quotes_days.map(&:downcase).include?(Date.today.strftime("%A").downcase)
              when "dependapanda"
                MessageBuilder.new(team, :panda).build
              else
                MessageBuilder.new(team, :seal).build
              end

    return if message.nil?

    poster = SlackPoster.new(team.channel, message.mood)
    poster.send_request(message.text)
  rescue StandardError => e
    puts "Error barking at team '#{team.name}': #{e.message}"
  end
end

require 'net/http'
require 'sinatra'
require './lib/seal'
require './lib/github_fetcher'
require './lib/message_builder'
require './lib/slack_poster'

class SealApp < Sinatra::Base

  get '/' do
    "Hello Seal"
  end

  post '/bark/:team_name/:secret' do
    if params[:secret] == ENV["SEAL_SECRET"]
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
  end

  post '/bark-quotes/:team_name' do
    Seal.new(params[:team_name], "quotes").bark
    "Seal received message with #{params[:team_name]} team name"
  end

  get '/slack-bark' do
    uri = URI('https://moody-seal-pr-25.herokuapp.com/slack-bark')
    response = Net::HTTP.get(uri)
    "#{response}"
    # response = HTTParty.get('https://moody-seal-pr-25.herokuapp.com/slack-bark')
    # puts "response body"
    # puts response.body
    # puts "response code"
    # response.code
    # puts "response message"
    # response.message
    # puts "response headers"
    # response.headers
    # puts "response headers inspect"
    # response.headers.inspect

    "end"
    #
    #  - request_payload #{request_payload} - slack_signing_secret #{request.env["SLACK_SIGNING_SECRET"]}"
    # slack_signing_secret = request.env["SLACK_SIGNING_SECRET"]
    # request_payload = JSON.parse(request.body.read)
    # if params[:secret] == ENV["SEAL_SECRET"]
    #   Seal.new(params[:team_name]).bark
    #   "Seal received message with #{params[:team_name]} team name"
    # end
  end

  post '/add-team' do
    if params[:secret] == ENV["SEAL_SECRET"]
      team = Team.create!(name: "#{params[:team_name]}")
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
  end

  post '/add-member' do
    if params[:secret] == ENV["SEAL_SECRET"]
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
  end

  get '/settings' do
    if params[:secret] == ENV["SEAL_SECRET"]
      team = Team.create!(name: "#{params[:team_name]}")
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
  end

  post '/settings-change' do
    if params[:secret] == ENV["SEAL_SECRET"]
      team = Team.create!(name: "#{params[:team_name]}")
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
  end
end

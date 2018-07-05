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

  post '/slack-bark' do
    slack_signing_secret = request.env["SLACK_SIGNING_SECRET"]
    request_payload = JSON.parse(request.body.read)
    "this is working - request_payload #{request_payload} - slack_signing_secret #{request.env["SLACK_SIGNING_SECRET"]}"
    if params[:secret] == ENV["SEAL_SECRET"]
      Seal.new(params[:team_name]).bark
      "Seal received message with #{params[:team_name]} team name"
    end
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

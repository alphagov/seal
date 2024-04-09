require "spec_helper"
require "fakefs/spec_helpers"
require "webmock/rspec"
require_relative "../lib/team_builder"

RSpec.describe TeamBuilder do
  include FakeFS::SpecHelpers

  let(:organisation) { "big_cats" }

  let(:uri) { URI("https://docs.publishing.service.gov.uk/repos.json") }

  let(:repos) do
    [{ "app_name" => "Brazil", "team" => "#govuk-jaguars" },
     { "app_name" => "rainforest", "team" => "#govuk-wildcats-team" },
     { "app_name" => "savanna", "team" => "#govuk-wildcats-team" },
     { "app_name" => "grassland", "team" => "#govuk-wildcats-team" },
     { "app_name" => "generic-repo", "team" => "govuk-generic-team" }]
  end

  before do
    stub_request(:get, uri).with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).to_return(status: 200, body: JSON.dump(repos), headers: {})

    FileUtils.mkdir_p(File.join(File.dirname(__FILE__), "../config"))
    File.write(File.join(File.dirname(__FILE__), "../config/#{organisation}.yml"),
               YAML.dump(
                 "lions" => {
                   "channel" => "#lions",
                   "exclude_titles" => [
                     "DO NOT MERGE",
                     "WIP",
                   ],
                   "exclude_labels" => [
                     "DO NOT MERGE",
                     "WIP",
                   ],
                   "use_labels" => true,
                   "compact" => true,
                   "quotes" => [
                     "This is a quote",
                     "This is also a quote",
                   ],
                   "quotes_days" => %w[
                     Monday
                     Tuesday
                     Wednesday
                     Thursday
                     Friday
                   ],
                   "repos" => %w[
                     Africa
                   ],
                 },
                 "tigers" => {
                   "channel" => "#tigers",
                 },
                 "cats" => {
                   "channel" => "#cats",
                 },
                 "govuk-jaguars" => {
                   "channel" => "#govuk-jaguars",
                 },
                 "govuk-wildcats" => {
                   "channel" => "#govuk-wildcats-team",
                 },
                 "govuk-generic-team" => {
                   "channel" => "#govuk-generic-team",
                   "repos" => %w[
                     generic-repo
                   ],
                 },
               ))
  end

  let(:env) { { "SEAL_ORGANISATION" => organisation } }

  let(:teams) { TeamBuilder.build(env:) }

  it "loads each team from the static config file" do
    expect(teams.count).to eq(6)
    expect(teams.map(&:channel)).to match_array(["#lions", "#tigers", "#cats", "#govuk-jaguars", "#govuk-wildcats-team", "#govuk-generic-team"])
  end

  it "loads all keys" do
    lions = teams.find { |t| t.channel == "#lions" }

    expect(lions.exclude_titles).to eq(["DO NOT MERGE", "WIP"])

    expect(lions.exclude_labels).to eq(["DO NOT MERGE", "WIP"])

    expect(lions.use_labels).to eq(true)
    expect(lions.compact).to eq(true)

    expect(lions.quotes).to eq(["This is a quote", "This is also a quote"])
  end

  it "provides sensible defaults" do
    tigers = teams.find { |t| t.channel == "#tigers" }

    expect(tigers.exclude_titles).to eq([])
    expect(tigers.exclude_labels).to eq([])
    expect(tigers.use_labels).to eq(false)
    expect(tigers.compact).to eq(false)
    expect(tigers.quotes).to eq([])
    expect(tigers.repos).to eq([])
  end

  it "raises an error if a GOV.UK team has manually added their repos to the YAML config file" do
    allow(TeamBuilder).to receive(:build).and_raise("govuk-generic-team is a GOV.UK team and shouldn't list repos in ./config/alphagov.yml")
    expect { teams }.to raise_error(RuntimeError, /govuk-generic-team is a GOV.UK team and shouldn't list repos in .*\/config\/alphagov.yml/)
  end

  it "gets non gov.uk team repos from the static config file if repos array is defined" do
    lions = teams.find { |t| t.channel == "#lions" }
    expect(lions.repos).to eq(%w[Africa])
  end

  it "gets gov.uk team repos from an external JSON file if repos array is not defined in static config file" do
    jaguars = teams.find { |t| t.channel == "#govuk-jaguars" }
    expect(jaguars.repos).to eq(%w[Brazil])
  end

  it "gets gov.uk team repos from an external JSON file if repos array is not defined in static config file and team channel differs to team name" do
    teams = TeamBuilder.build(env:, team_name: "govuk-wildcats")
    expect(teams.first.repos).to eq(%w[rainforest savanna grassland])
  end

  it "allows the overriding of options via environment variables" do
    env.merge!("GITHUB_EXCLUDE_LABELS" => "new,labels")

    teams.each do |team|
      expect(team.exclude_labels).to eq(%w[new labels])
    end
  end

  it "allows the selection of a single team" do
    teams = TeamBuilder.build(env:, team_name: "tigers")

    expect(teams.count).to eq(1)
    expect(teams.first.channel).to eq("#tigers")
  end

  it "short-circuits if the team name does not appear in the configuration file" do
    teams = TeamBuilder.build(env:, team_name: "cheetas")

    expect(teams.count).to eq(0)
  end
end

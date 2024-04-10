require "./lib/gem_version_checker"

RSpec.describe GemVersionChecker do
  subject(:gem_version_checker) { described_class.new }

  let(:slack_poster) { instance_double(SlackPoster, send_request: nil) }

  before do
    allow(SlackPoster).to receive(:new).and_return(slack_poster)
  end

  it "fetches version number of a gem from rubygems" do
    stub_rubygems_call("6.0.1")

    expect(gem_version_checker.fetch_rubygems_version("example")).to eq("6.0.1")
  end

  it "detects when there are files changed since the last release that are built into the gem" do
    stub_rubygems_call("1.2.2")
    stub_files_changed_since_tag(["lib/foo.rb"])

    expect(gem_version_checker.detect_version_discrepancies("example")).to match("1.2.2")
  end

  def stub_files_changed_since_tag(files)
    allow(gem_version_checker).to receive(:files_changed_since_tag) do
      files
    end
  end

  def stub_rubygems_call(version)
    repo = { "version": version }
    stub_request(:get, "https://rubygems.org/api/v1/gems/example.json")
      .to_return(status: 200, body: repo.to_json, headers: {})
  end
end

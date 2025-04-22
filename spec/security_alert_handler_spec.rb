require "spec_helper"
require_relative "../lib/security_alert_handler"
require "ostruct"

RSpec.describe SecurityAlertHandler do
  let(:github) { double("Github") }
  let(:organisation) { "test-org" }
  let(:repos) { %w[repo1 repo2] }

  subject(:handler) do
    described_class.new(github, organisation, repos)
  end

  let(:sample_alerts) do
    [
      {
        repo: "repo1",
        package_manager: "npm",
        dependency_name: "lodash",
        vulnerable_version_ranges: [">=4.0.0", "<4.17.13"],
        url: "https://github.com/test-org/repo1/security/dependabot/package-lock.json/npm/lodash/open",
        severity: "high",
      },
      {
        repo: "repo2",
        package_manager: "npm",
        dependency_name: "lodash",
        vulnerable_version_ranges: [">=4.0.0", "<4.17.12"],
        url: "https://github.com/test-org/repo2/security/dependabot/package-lock.json/npm/lodash/open",
        severity: "high",
      },
    ]
  end

  let(:api_response) do
    [
      {
        dependency: {
          package: {
            ecosystem: "npm",
            name: "lodash",
          },
        },
        security_vulnerability: {
          vulnerable_version_range: ">=4.0.0, <4.17.13",
          severity: "high",
        },
        html_url: "https://github.com/test-org/repo1/security/dependabot/package-lock.json/npm/lodash/open",
      },
    ]
  end

  before do
    repos.each do |repo|
      allow(github).to receive(:get).with(
        "https://api.github.com/repos/test-org/#{repo}/dependabot/alerts",
        accept: "application/vnd.github+json",
        state: "open",
      ).and_return(api_response)

      allow(github).to receive(:get).with(
        "https://api.github.com/repos/test-org/#{repo}/code-scanning/alerts",
        accept: "application/vnd.github+json",
      ).and_return([
        { state: "open" },
        { state: "closed" },
      ])
    end

    allow(handler).to receive(:fetch_security_alerts).and_return(sample_alerts)
  end

  describe "#security_alerts_count" do
    context "when GitHub API errors occur" do
      before do
        allow(github).to receive(:get).and_raise(StandardError.new("API error"))
      end

      it "returns 0 for security_alerts_count" do
        handler = SecurityAlertHandler.new(github, organisation, repos)
        expect(handler.security_alerts_count).to eq(0)
      end

      it "returns 4 for github_api_errors" do
        handler = SecurityAlertHandler.new(github, organisation, repos)
        expect(handler.github_api_errors).to eq(4)
      end
    end

    context "when there are no security alerts" do
      before do
        allow(github).to receive(:get).and_return([])
      end

      it "returns 0 for security_alerts_count" do
        handler = SecurityAlertHandler.new(github, organisation, repos)
        expect(handler.security_alerts_count).to eq(0)
      end
    end

    it "returns the total number of security alerts" do
      expect(handler.security_alerts_count).to eq(2)
    end
  end

  describe "#filter_security_alerts" do
    it "filters security alerts by repo" do
      filtered_alerts = handler.filter_security_alerts("repo1")
      expect(filtered_alerts.length).to eq(1)
      expect(filtered_alerts.first[:repo]).to eq("repo1")
    end
  end

  describe "#label_for_branch" do
    let(:branch) { "dependabot/npm/lodash-4.17.13" }
    let(:title) { "Bump lodash from 4.16.12 to 4.17.13" }
    let(:alerts_for_repo) { handler.filter_security_alerts("repo1") }

    context "when the branch solves a security alert" do
      it "returns a hash with the security label information" do
        label = handler.label_for_branch(branch, title, alerts_for_repo)
        expect(label).to be_a(Hash)
        expect(label[:url]).to eq("https://github.com/test-org/repo1/security/dependabot?q=package:lodash+is:open")
        expect(label[:severity]).to eq("high")
        expect(label[:count]).to eq(1)
      end
    end

    context "when the branch doesn't solve any security alert" do
      let(:branch) { "dependabot/npm/lodash-4.16.12" }
      let(:title) { "Bump lodash from 4.16.11 to 4.16.12" }

      it "returns nil" do
        label = handler.label_for_branch(branch, title, alerts_for_repo)
        expect(label).to be_nil
      end
    end
  end
end

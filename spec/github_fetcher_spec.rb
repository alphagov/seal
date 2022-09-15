require "spec_helper"
require_relative "../lib/github_fetcher"

RSpec.describe GithubFetcher do
  let(:team) do
    Team.new(
      github_team:,
      use_labels:,
      exclude_labels:,
      exclude_titles:,
      repos:,
    )
  end

  subject(:github_fetcher) do
    described_class.new(team)
  end

  let(:fake_octokit_client) { double(Octokit::Client) }
  let(:whitehall_repo_name) { "#{ENV['SEAL_ORGANISATION']}/whitehall" }
  let(:govuk_docker_repo_name) { "#{ENV['SEAL_ORGANISATION']}/govuk-docker" }
  let(:content_store_repo_name) { "#{ENV['SEAL_ORGANISATION']}/content-store" }
  let(:expected_open_prs) do
    [
      {
        title: "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host",
        link: "https://github.com/alphagov/whitehall/pull/2266",
        author: "mattbostock",
        repo: "whitehall",
        comments_count: 1,
        thumbs_up: 1,
        approved: false,
        updated: Date.parse("2015-07-13 ((2457217j,0s,0n),+0s,2299161j)"),
        labels: wip_or_not,
      },

      {
        title: "Remove all Import-related code",
        link: "https://github.com/alphagov/govuk-docker/pull/2248",
        author: "tekin",
        repo: "govuk-docker",
        comments_count: 5,
        thumbs_up: 0,
        approved: true,
        updated: Date.parse("2015-07-17 ((2457221j,0s,0n),+0s,2299161j)"),
        labels: [],
      },
      {
        approved: false,
        author: "lauramipsum",
        comments_count: 0,
        labels: [],
        link: "https://github.com/alphagov/content-store/pull/2295",
        repo: "content-store",
        thumbs_up: 0,
        title: "Enable ssh key signing",
        updated: Date.parse("2015-07-17 ((2457221j,0s,0n),+0s,2299161j)"),
      },
    ]
  end

  let(:exclude_labels) { nil }
  let(:exclude_titles) { nil }
  let(:repos) { %w[whitehall govuk-docker content-store] }

  let(:github_team) { nil }

  let(:pull_2266) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: "mattbostock"),
           title: "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host",
           html_url: "https://github.com/alphagov/whitehall/pull/2266",
           number: 2266,
           review_comments: 1,
           comments: 0,
           updated_at: "2015-07-13 01:00:44 UTC",
           draft: false,
           head: double(Sawyer::Resource, repo: double(Sawyer::Resource, name: "whitehall")),
           labels: [
             { name: "wip" },
           ])
  end

  let(:pull_2248) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: "tekin"),
           title: "Remove all Import-related code",
           html_url: "https://github.com/alphagov/govuk-docker/pull/2248",
           number: 2248,
           review_comments: 1,
           comments: 4,
           updated_at: "2015-07-17 01:00:44 UTC",
           draft: false,
           head: double(Sawyer::Resource, repo: double(Sawyer::Resource, name: "govuk-docker")),
           labels: [])
  end

  let(:pull_2295) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: "lauramipsum"),
           title: "Enable ssh key signing",
           html_url: "https://github.com/alphagov/content-store/pull/2295",
           number: 2295,
           review_comments: 0,
           comments: 0,
           updated_at: "2015-07-17 01:00:44 UTC",
           draft: false,
           head: double(Sawyer::Resource, repo: double(Sawyer::Resource, name: "content-store")),
           labels: [])
  end

  let(:comments_2266) do
    [
      "You should add more seal images on the front end",
      "Sure! I have done it now",
      "LGTM :+1:",
    ].map { |body| double(Sawyer::Resource, body:) }
  end

  let(:comments_2248) do
    [
      "Could you embed a seal song?",
      "Sure! Please send me the recording",
    ].map { |body| double(Sawyer::Resource, body:) }
  end

  let(:comments_2295) do
    []
  end

  let(:reviews_2248) do
    [
      double(Sawyer::Resource, state: "APPROVED"),
    ]
  end

  let(:reviews_2266) { [] }

  let(:reviews_2295) { [] }

  let(:titles) { github_fetcher.list_pull_requests.map { |pr| pr[:title] } }

  let(:no_prs) { [] }

  before do
    allow(Octokit::Client).to receive(:new).and_return(fake_octokit_client)
    allow(fake_octokit_client).to receive_message_chain("user.login")
    allow(fake_octokit_client).to receive(:auto_paginate=).with(false)

    allow(fake_octokit_client).to receive(:pull_requests).with(
      "alphagov/whitehall", { state: :open, sort: :created }
    ).and_return([pull_2266])

    allow(fake_octokit_client).to receive(:pull_requests).with(
      "alphagov/govuk-docker", { state: :open, sort: :created }
    ).and_return([pull_2248])

    allow(fake_octokit_client).to receive(:pull_requests).with(
      "alphagov/content-store", { state: :open, sort: :created }
    ).and_return([pull_2295])

    allow(fake_octokit_client).to receive(:issue_comments).with(whitehall_repo_name, 2266).and_return(comments_2266)
    allow(fake_octokit_client).to receive(:issue_comments).with(govuk_docker_repo_name,
                                                                2248).and_return(comments_2248)
    allow(fake_octokit_client).to receive(:issue_comments).with(content_store_repo_name, 2295).and_return(comments_2295)

    allow(fake_octokit_client).to receive(:pull_request).with(govuk_docker_repo_name, 2248).and_return(pull_2248)
    allow(fake_octokit_client).to receive(:pull_request).with(whitehall_repo_name, 2266).and_return(pull_2266)
    allow(fake_octokit_client).to receive(:pull_request).with(content_store_repo_name, 2295).and_return(pull_2295)

    allow(fake_octokit_client).to receive(:get).with(%r{repos/alphagov/[\w-]+/pulls/2248/reviews}).and_return(reviews_2248)
    allow(fake_octokit_client).to receive(:get).with(%r{repos/alphagov/[\w-]+/pulls/2266/reviews}).and_return(reviews_2266)
    allow(fake_octokit_client).to receive(:get).with(%r{repos/alphagov/[\w-]+/pulls/2295/reviews}).and_return(reviews_2295)
  end

  shared_examples_for "fetching from GitHub" do
    describe "#list_pull_requests" do
      it "displays open pull requests open on the team's repos" do
        expect(github_fetcher.list_pull_requests).to match expected_open_prs
      end
    end

    describe "#pull_requests_from_github" do
      it "returns an empty array when there are no items returned from search" do
        allow(fake_octokit_client).to receive(:pull_requests).and_return(no_prs)

        expect(github_fetcher.pull_requests_from_github).to eq([])
      end
    end
  end

  context "labels turned on" do
    let(:use_labels) { true }

    context 'excluding "designer" label' do
      let(:exclude_labels) { %w[designer] }
      let(:wip_or_not) { %w[wip] }

      it_behaves_like "fetching from GitHub"
    end

    context 'excluding "wip" label' do
      let(:exclude_labels) { %w[wip] }

      it "filters out the wip" do
        expect(titles).to include("Remove all Import-related code")
        expect(titles).not_to include("[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host")
      end
    end
  end

  context "title exclusions" do
    let(:use_labels) { false }

    context "excluding no titles" do
      let(:wip_or_not) { [] }

      it_behaves_like "fetching from GitHub"
    end

    context 'excluding "BLAH BLAH BLAH" title' do
      let(:exclude_titles) { ["BLAH BLAH BLAH"] }
      let(:wip_or_not) { [] }

      it_behaves_like "fetching from GitHub"
    end

    context 'excluding "DISCUSSION" title' do
      let(:exclude_titles) { ["FOR DISCUSSION ONLY"] }

      it "filters out the DISCUSSION" do
        expect(titles).not_to include("[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host")
        expect(titles).to include("Remove all Import-related code")
      end
    end
  end

  context "with github team configured" do
    let(:use_labels) { false }
    let(:github_team) { "content-store-devs" }

    let(:github_team_repos) do
      [
        double(Sawyer::Resource, name: "content-store"),
      ]
    end

    before do
      allow(fake_octokit_client).to receive(:get).with("/orgs/#{ENV['SEAL_ORGANISATION']}/teams/#{github_team}/repos").and_return(github_team_repos)
      allow(fake_octokit_client).to receive(:issue_comments).with(content_store_repo_name,
                                                                  2295).and_return(comments_2295)
      allow(fake_octokit_client).to receive(:pull_request).with(content_store_repo_name,
                                                                2295).and_return(pull_2295)
      allow(fake_octokit_client).to receive(:get).with(%r{repos/alphagov/[\w-]+/pulls/2295/reviews}).and_return(reviews_2295)
    end

    context "without repos configured" do
      let(:repos) { [] }

      it "only shows PRs for repos owned by the github team" do
        expect(titles).to match_array(["Enable ssh key signing"])
      end
    end

    context "with repos configured" do
      let(:repos) { %w[whitehall govuk-docker] }

      it "shows PRs for repos owned by the github team and the additional configured repos" do
        expect(titles).to match_array(["Enable ssh key signing",
                                       "Remove all Import-related code",
                                       "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host"])
      end
    end
  end
end

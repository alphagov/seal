require "spec_helper"
require_relative "../lib/github_fetcher"

RSpec.describe GithubFetcher do
  let(:team) {
    Team.new(
      github_team: github_team,
      use_labels: use_labels,
      exclude_labels: exclude_labels,
      exclude_titles: exclude_titles,
      repos: repos,
    )
  }

  subject(:github_fetcher) do
    described_class.new(team)
  end

  let(:fake_octokit_client) { double(Octokit::Client) }
  let(:whitehall_repo_name) { "#{ENV['SEAL_ORGANISATION']}/whitehall" }
  let(:whitehall_rebuild_repo_name) { "#{ENV['SEAL_ORGANISATION']}/whitehall-rebuild" }
  let(:whitehall_security_repo_name) { "#{ENV['SEAL_ORGANISATION']}/whitehall-security" }
  let(:blocked_and_wip) do
    [
      {
        'url' => 'https://api.github.com/repos/alphagov/whitehall/labels/blocked',
        'name' => 'blocked',
        'color' => 'e11d21'
      },
      {
        'url' => 'https://api.github.com/repos/alphagov/whitehall/labels/wip',
        'name' => 'wip',
        'color' => 'fbca04'
      }
    ]
  end

  let(:expected_open_prs) do
    [
      {
        title: '[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host',
        link: 'https://github.com/alphagov/whitehall/pull/2266',
        author: 'mattbostock',
        repo: 'whitehall',
        comments_count: 1,
        thumbs_up: 1,
        approved: false,
        updated: Date.parse('2015-07-13 ((2457217j,0s,0n),+0s,2299161j)'),
        labels: [],
      },

      {
        title: 'Remove all Import-related code',
        link: 'https://github.com/alphagov/whitehall-rebuild/pull/2248',
        author: 'tekin',
        repo: 'whitehall-rebuild',
        comments_count: 5,
        thumbs_up: 0,
        approved: true,
        updated: Date.parse('2015-07-17 ((2457221j,0s,0n),+0s,2299161j)'),
        labels: labels,
      }
    ]
  end

  let(:labels) { [] }

  let(:exclude_labels) { nil }
  let(:exclude_titles) { nil }
  let(:repos) { nil }

  let(:github_team) { nil }

  let(:pull_2266) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: 'mattbostock'),
           title: '[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host',
           html_url: 'https://github.com/alphagov/whitehall/pull/2266',
           number: 2266,
           review_comments: 1,
           comments: 0,
           updated_at: '2015-07-13 01:00:44 UTC'
          )
  end

  let(:pull_2248) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: 'tekin'),
           title: 'Remove all Import-related code',
           html_url: 'https://github.com/alphagov/whitehall-rebuild/pull/2248',
           number: 2248,
           review_comments: 1,
           comments: 4,
           updated_at: '2015-07-17 01:00:44 UTC'
          )
  end

  let(:pull_2295) do
    double(Sawyer::Resource,
           user: double(Sawyer::Resource, login: 'lauramipsum'),
           title: 'Enable ssh key signing',
           html_url: 'https://github.com/alphagov/whitehall-security/pull/2295',
           number: 2295,
           review_comments: 0,
           comments: 0,
           updated_at: '2015-07-17 01:00:44 UTC'
          )
  end

  let(:comments_2266) do
    [
      "You should add more seal images on the front end",
      "Sure! I have done it now",
      "LGTM :+1:"
    ].map { |body| double(Sawyer::Resource, body: body)}
  end

  let(:comments_2248) do
    [
      "Could you embed a seal song?",
      "Sure! Please send me the recording"
    ].map { |body| double(Sawyer::Resource, body: body)}
  end

  let(:comments_2295) do
    []
  end

  let(:reviews_2248) do
    [
      double(Sawyer::Resource, state: "APPROVED" )
    ]
  end

  let(:reviews_2266) { [] }

  let(:reviews_2295) { [] }

  let(:titles) { github_fetcher.list_pull_requests.map { |pr| pr[:title] } }

  before do
    allow(Octokit::Client).to receive(:new).and_return(fake_octokit_client)
    allow(fake_octokit_client).to receive_message_chain('user.login')
    allow(fake_octokit_client).to receive(:auto_paginate=).with(false)
    response = double(items: [pull_2266, pull_2248, pull_2295])
    allow(fake_octokit_client).to receive(:search_issues).with("is:pr state:open user:alphagov archived:false -is:draft", per_page: 100).and_return(response)
    allow(fake_octokit_client).to receive(:last_response).and_return(double(data: response, rels: { next: nil }))

    allow(fake_octokit_client).to receive(:issue_comments).with(whitehall_repo_name, 2266).and_return(comments_2266)
    allow(fake_octokit_client).to receive(:issue_comments).with(whitehall_rebuild_repo_name, 2248).and_return(comments_2248)

    allow(fake_octokit_client).to receive(:pull_request).with(whitehall_rebuild_repo_name, 2248).and_return(pull_2248)
    allow(fake_octokit_client).to receive(:pull_request).with(whitehall_repo_name, 2266).and_return(pull_2266)

    allow(fake_octokit_client).to receive(:get).with(%r"repos/alphagov/[\w-]+/pulls/2248/reviews").and_return(reviews_2248)
    allow(fake_octokit_client).to receive(:get).with(%r"repos/alphagov/[\w-]+/pulls/2266/reviews").and_return(reviews_2266)
  end

  shared_examples_for 'fetching from GitHub' do
    describe '#list_pull_requests' do
      it "displays open pull requests open on the team's repos" do
        expect(github_fetcher.list_pull_requests).to match expected_open_prs
      end
    end

    describe '#pull_requests_from_github' do
      it "returns an empty array when there are no items returned from search" do
        allow(fake_octokit_client).to receive(:last_response).and_return(
          double(data: double(items: []), rels: { next: nil })
        )

        expect(github_fetcher.pull_requests_from_github).to eq([])
      end

      it "steps through each page of results" do
        ENV["THROTTLE_SECS"] = "0"
        second_page = double(data: double(items: [pull_2248]), rels: { next: nil })
        first_page = double(data: double(items: [pull_2266]), rels: { next: double(get: second_page) })
        allow(fake_octokit_client).to receive(:last_response).and_return(first_page)

        expect(github_fetcher.pull_requests_from_github).to eq([pull_2266, pull_2248])
      end
    end
  end

  context 'labels turned on' do
    let(:use_labels) { true }
    let(:labels) { blocked_and_wip }

    before do
      allow(fake_octokit_client).to receive(:labels_for_issue).with(whitehall_rebuild_repo_name, 2248).and_return(blocked_and_wip)
      allow(fake_octokit_client).to receive(:labels_for_issue).with(whitehall_repo_name, 2266).and_return([])
      allow(fake_octokit_client).to receive(:labels_for_issue).with(whitehall_security_repo_name, 2295).and_return([])
    end

    context 'excluding nothing' do
      it_behaves_like 'fetching from GitHub'
    end

    context 'excluding "designer" label' do
      let(:exclude_labels) { ['designer'] }

      it_behaves_like 'fetching from GitHub'
    end

    context 'excluding "WIP" label' do
      let(:exclude_labels) { ['WIP'] }

      it 'filters out the WIP' do
        expect(titles).not_to include('Remove all Import-related code')
        expect(titles).to include('[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host')
      end
    end

    context 'excluding "wip" label' do
      let(:exclude_labels) { ['wip'] }

      it 'filters out the wip' do
        expect(titles).not_to include('Remove all Import-related code')
        expect(titles).to include('[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host')
      end
    end

    context 'excluding "whitehall-rebuild" repo' do
      let(:repos) { ['whitehall-rebuild'] }

      it 'filters out PRs NOT from the "whitehall-rebuild" repo' do
        expect(titles).to match_array(['Remove all Import-related code'])
      end
    end
  end

  context 'labels turned off' do
    let(:use_labels) { false }

    it_behaves_like 'fetching from GitHub'
    context 'title exclusions' do
      context 'excluding no titles' do
        it_behaves_like 'fetching from GitHub'
      end

      context 'excluding "BLAH BLAH BLAH" title' do
        let(:exclude_titles) { ['BLAH BLAH BLAH'] }

        it_behaves_like 'fetching from GitHub'
      end

      context 'excluding "DISCUSSION" title' do
        let(:exclude_titles) { ['FOR DISCUSSION ONLY'] }

        it 'filters out the DISCUSSION' do
          expect(titles).not_to include('[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host')
          expect(titles).to include('Remove all Import-related code')
        end
      end

      context 'excluding "discussion" title' do
        let(:exclude_titles) { ['for discussion only'] }

        it 'filters out the discussion' do
          expect(titles).not_to include('[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host')
          expect(titles).to include('Remove all Import-related code')
        end
      end
    end
  end

  context 'with github team configured' do

    let(:use_labels) { false }
    let(:github_team) { 'whitehall-security-devs' }

    let(:github_team_repos) do
      [
        double(Sawyer::Resource, name: "whitehall-security" )
      ]
    end

    before do
      allow(fake_octokit_client).to receive(:get).with("/orgs/#{ENV['SEAL_ORGANISATION']}/teams/#{github_team}/repos").and_return(github_team_repos)
      allow(fake_octokit_client).to receive(:issue_comments).with(whitehall_security_repo_name, 2295).and_return(comments_2295)
      allow(fake_octokit_client).to receive(:pull_request).with(whitehall_security_repo_name, 2295).and_return(pull_2295)
      allow(fake_octokit_client).to receive(:get).with(%r"repos/alphagov/[\w-]+/pulls/2295/reviews").and_return(reviews_2295)
    end
     
    context 'without repos configured' do
      let(:repos) { [] }

      it 'only shows PRs for repos owned by the github team' do
        expect(titles).to match_array(["Enable ssh key signing"])
      end
    end
     
    context 'with repos configured' do
      let(:repos) { ['whitehall', 'whitehall-rebuild'] }

      it 'shows PRs for repos owned by the github team and the additional configured repos' do
        expect(titles).to match_array(["Enable ssh key signing","Remove all Import-related code","[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host"])
      end
    end
  end
end

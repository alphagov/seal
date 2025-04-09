require "spec_helper"
require "./lib/message_builder"

RSpec.describe MessageBuilder do
  let(:security_alerts) { false }
  let(:security_alerts_count) { 0 }
  let(:github_api_errors) { 0 }
  let(:repos) { %w[repo1 repo2] }
  let(:team) { double(:team, security_alerts:, compact: false, dependency_prs:, repos:) }
  let(:pull_requests) { [] }
  let(:dependency_prs) { false }
  let(:github_fetcher) { double(:github_fetcher, list_pull_requests: pull_requests, security_alerts_count:, github_api_errors:) }
  let(:animal) { :seal }
  subject(:message_builder) { MessageBuilder.new(team, animal) }

  let(:no_unapproved_pull_requests) do
    [
      {
        title: "Some approved PR",
        link: "https://github.com/alphagov/whitehall/pull/9999",
        author: "helpful_person",
        repo: "whitehall",
        branch: "sample-branch-1",
        comments_count: 5,
        thumbs_up: 0,
        approved: true,
        created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
    ]
  end

  let(:recent_pull_requests) do
    [
      {
        title: "Remove all Import-related code",
        link: "https://github.com/alphagov/whitehall/pull/2248",
        author: "tekin",
        repo: "whitehall",
        branch: "sample-branch-2",
        comments_count: 5,
        thumbs_up: 0,
        approved: false,
        created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
      {
        title: "Some approved PR",
        link: "https://github.com/alphagov/whitehall/pull/9999",
        author: "helpful_person",
        repo: "whitehall",
        branch: "sample-branch-1",
        comments_count: 5,
        thumbs_up: 0,
        approved: true,
        created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
    ]
  end

  let(:old_and_new_pull_requests) do
    [
      {
        title: "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host",
        link: "https://github.com/alphagov/whitehall/pull/2266",
        author: "mattbostock",
        repo: "whitehall",
        branch: "sample-branch-3",
        comments_count: 1,
        thumbs_up: 1,
        approved: false,
        created: Date.parse("2015-07-13 ((2457217j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
      {
        title: "Remove all Import-related code",
        link: "https://github.com/alphagov/whitehall/pull/2248",
        author: "tekin",
        repo: "whitehall",
        branch: "sample-branch-2",
        comments_count: 5,
        thumbs_up: 0,
        approved: false,
        created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
      {
        title: "Add extra examples to the specs",
        link: "https://github.com/alphagov/seal/pull/9999",
        author: "elliotcm",
        repo: "seal",
        branch: "sample-branch-4",
        comments_count: 5,
        thumbs_up: 0,
        approved: false,
        created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
        labels: [],
      },
    ]
  end

  before do
    Timecop.freeze(Time.local(2015, 0o7, 18))

    allow(GithubFetcher).to receive(:new).with(team, dependency_prs:).and_return(github_fetcher)
  end

  context "with labels" do
    let(:mood) { "informative" }
    let(:pull_requests) do
      [
        {
          title: "My WIP",
          link: "https://github.com/org/repo/pull/42",
          author: "Agatha Christie",
          repo: "repo",
          branch: "sample-branch-5",
          comments_count: 0,
          thumbs_up: 0,
          approved: false,
          created: Date.today,
          labels: [
            { "name" => "wip" },
            { "name" => "blocked" },
          ],
        },
      ]
    end

    it "includes the labels in the built message" do
      expect(message_builder.build.text).to include(
        "[wip] [blocked] <https://github.com/org/repo/pull/42|My WIP> - 0 comments",
      )
    end
  end

  context "pull requests are recent" do
    let(:pull_requests) { recent_pull_requests }

    it "builds informative message excluding approved PRs" do
      expect(message_builder.build.text).to eq("Hello team!\n\nHere are the pull requests that need to be reviewed today:\n\n1) *whitehall* | tekin | created/undrafted yesterday\n<https://github.com/alphagov/whitehall/pull/2248|Remove all Import-related code> - 5 comments\n\nMerry reviewing!")
    end

    it "has an informative poster mood" do
      expect(message_builder.build.mood).to eq("informative")
    end
  end

  context "no unapproved pull requests" do
    let(:pull_requests) { no_unapproved_pull_requests }

    it "builds seal of approval message" do
      expect(message_builder.build.text).to eq("Aloha team! It's a beautiful day! :happyseal: :happyseal: :happyseal:\n\nNo pull requests to review today! :rainbow: :sunny: :metal: :tada:")
    end

    it "has an approval poster mood" do
      expect(message_builder.build.mood).to eq("approval")
    end
  end

  context "there are some PRs that are over 2 days old" do
    let(:mood) { "angry" }
    let(:pull_requests) { old_and_new_pull_requests }

    context "and some recent ones" do
      before { Timecop.freeze(Time.local(2015, 0o7, 18)) }
      it "builds message" do
        expect(message_builder.build.text).to eq("AAAAAAARGH! This pull request is over 2 days old.\n\n1) *whitehall* | mattbostock | created/undrafted 5 days ago | 1 :+1:\n<https://github.com/alphagov/whitehall/pull/2266|[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host> - 1 comment\n\n\nThere are also these pull requests that need to be reviewed today:\n\n1) *whitehall* | tekin | created/undrafted yesterday\n<https://github.com/alphagov/whitehall/pull/2248|Remove all Import-related code> - 5 comments\n2) *seal* | elliotcm | created/undrafted yesterday\n<https://github.com/alphagov/seal/pull/9999|Add extra examples to the specs> - 5 comments")
      end
    end

    context "but no recent ones" do
      before { Timecop.freeze(Time.local(2015, 0o7, 16)) }
      it "builds message" do
        expect(message_builder.build.text).to eq("AAAAAAARGH! This pull request is over 2 days old.\n\n1) *whitehall* | mattbostock | created/undrafted 3 days ago | 1 :+1:\n<https://github.com/alphagov/whitehall/pull/2266|[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host> - 1 comment\n\n\nThere are also these pull requests that need to be reviewed today:\n\n1) *whitehall* | tekin | created/undrafted -1 days ago\n<https://github.com/alphagov/whitehall/pull/2248|Remove all Import-related code> - 5 comments\n2) *seal* | elliotcm | created/undrafted -1 days ago\n<https://github.com/alphagov/seal/pull/9999|Add extra examples to the specs> - 5 comments")
      end
    end

    it "has an angry poster mood" do
      expect(message_builder.build.mood).to eq("angry")
    end

    context "when in compact mode" do
      let(:team) { double(:team, compact: true) }

      before { Timecop.freeze(Time.local(2015, 0o7, 18)) }

      it "builds a more compact message" do
        expect(message_builder.build.text).to eq("*Old pull requests*:\n1) whitehall: <https://github.com/alphagov/whitehall/pull/2266|[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host>\n\n*Recent pull requests*:\n1) whitehall: <https://github.com/alphagov/whitehall/pull/2248|Remove all Import-related code>\n2) seal: <https://github.com/alphagov/seal/pull/9999|Add extra examples to the specs>")
      end
    end
  end

  context "rotting" do
    let(:pull_request) do
      {
        title: "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host",
        link: "https://github.com/alphagov/whitehall/pull/2266",
        author: "mattbostock",
        repo: "whitehall",
        comments_count: "1",
        thumbs_up: "0",
        created: Date.parse("2015-07-13 ((2457217j,0s,0n),+0s,2299161j)"),
      }
    end

    let(:pull_requests) { [pull_request] }

    context "old PR" do
      before do
        Timecop.freeze(Time.local(2015, 0o7, 16))
      end

      it "is rotten" do
        expect(message_builder).to be_rotten(pull_request)
      end
    end

    context "recent PR" do
      before do
        Timecop.freeze(Time.local(2015, 0o7, 15))
      end

      it "is not rotten" do
        expect(message_builder).to_not be_rotten(pull_request)
      end
    end

    context "old PR recently marked ready for review" do
      let(:pull_request) do
        {
          title: "[FOR DISCUSSION ONLY] Remove Whitehall.case_study_preview_host",
          link: "https://github.com/alphagov/whitehall/pull/2266",
          author: "mattbostock",
          repo: "whitehall",
          branch: "sample-branch-3",
          comments_count: "1",
          thumbs_up: "0",
          created: Date.new(2015, 6, 13),
          marked_ready_for_review_at: Date.new(2015, 7, 13),
        }
      end

      before do
        Timecop.freeze(Time.local(2015, 7, 15))
      end

      it "is not rotten" do
        expect(message_builder).to_not be_rotten(pull_request)
      end
    end
  end

  context "panda scenarios" do
    let(:animal) { :panda }
    let(:dependency_prs) { true }
    let(:dependabot_pull_requests) do
      [
        {
          title: "Remove all Import-related code",
          link: "https://github.com/alphagov/whitehall/pull/2248",
          author: "dependabot",
          repo: "whitehall",
          branch: "sample-branch-6",
          comments_count: 5,
          thumbs_up: 0,
          approved: false,
          created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
          labels: [],
        },
        {
          title: "Some approved PR",
          link: "https://github.com/alphagov/whitehall/pull/9999",
          author: "dependabot",
          repo: "whitehall",
          branch: "sample-branch-7",
          comments_count: 5,
          thumbs_up: 0,
          approved: true,
          created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
          labels: [],
        },
      ]
    end
    let(:renovate_pull_requests) do
      [
        {
          title: "Your Repo Made Perfect",
          link: "https://github.com/alphagov/whitehall/pull/2828",
          author: "govuk-ci",
          repo: "whitehall",
          branch: "renovate/sample-branch",
          comments_count: 5,
          thumbs_up: 0,
          approved: false,
          created: Date.parse("2015-07-17 ((2457221j, 0s, 0n), +0s, 2299161j)"),
          labels: [],
        },
      ]
    end

    context "security_alerts=False, no dependabot or Renovate PRs" do
      let(:pull_requests) { [] }
      let(:security_alerts) { false }

      it "does not post a message" do
        expect(message_builder.build).to be_nil
      end
    end

    context "security_alerts=False, dependabot PRs present" do
      let(:pull_requests) { dependabot_pull_requests }
      let(:security_alerts) { false }

      it "posts a message without security info" do
        expect(message_builder.build.text).to include("You have 2 automatic dependency upgrade PRs open on the following apps:")
        expect(message_builder.build.text).not_to include("security alert")
      end
    end

    context "security_alerts=False, Renovate PRs present" do
      let(:pull_requests) { renovate_pull_requests }
      let(:security_alerts) { false }

      it "posts a message without security info" do
        expect(message_builder.build.text).to include("You have 1 automatic dependency upgrade PR open on the following app:")
        expect(message_builder.build.text).not_to include("security alert")
      end
    end

    context "security_alerts=True, no dependabot or Renovate PRs" do
      let(:security_alerts) { true }
      let(:pull_requests) { [] }

      it "does not post a message" do
        expect(message_builder.build).to be_nil
      end
    end

    context "security_alerts=True, dependabot PRs present" do
      let(:security_alerts) { true }
      let(:security_alerts_count) { 1 }
      let(:pull_requests) { dependabot_pull_requests }

      it "posts a message with security info" do
        expect(message_builder.build.text).to include("You have 2 automatic dependency upgrade PRs open on the following apps:")
        expect(message_builder.build.text).to include("1 security alert")
      end

      let(:github_api_errors) { 2 }

      it "shows a warning if there are API errors" do
        expect(message_builder.build.text).to include(":warning: 2 errors fetching security alerts.")
        expect(message_builder.build.text).to include("1 security alert")
      end
    end

    context "security_alerts=True, Renovate PRs present" do
      let(:security_alerts) { true }
      let(:security_alerts_count) { 1 }
      let(:pull_requests) { renovate_pull_requests }

      it "posts a message with security info" do
        expect(message_builder.build.text).to include("You have 1 automatic dependency upgrade PR open on the following app:")
        expect(message_builder.build.text).to include("1 security alert")
      end

      let(:github_api_errors) { 2 }

      it "shows a warning if there are API errors" do
        expect(message_builder.build.text).to include(":warning: 2 errors fetching security alerts.")
        expect(message_builder.build.text).to include("1 security alert")
      end
    end
  end
end

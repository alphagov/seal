require "spec_helper"
require_relative "../lib/seal"
require_relative "../lib/team"

RSpec.describe Seal do
  subject(:seal) { described_class.new(teams) }

  let(:lions) do
    Team.new(
      slack_channel: "#lions",
      quotes: ["go lions!"],
      quotes_days: %w[Monday tuesday Wednesday],
    )
  end
  let(:tigers) do
    Team.new(
      slack_channel: "#tigers",
    )
  end
  let(:cats) do
    Team.new(
      slack_channel: "#cats",
      quotes: ["go cats!"],
      quotes_days: %w[yarn catnip nap scratches mischief],
    )
  end
  let(:teams) do
    [
      lions,
      tigers,
      cats,
    ]
  end

  let(:slack_poster) { instance_double(SlackPoster, send_request: nil) }
  let(:message_builder) { instance_double(MessageBuilder, build: message) }
  let(:message) { instance_double(Message, mood: "", text: "") }

  describe ".bark(mode: nil)" do
    before do
      allow(SlackPoster).to receive(:new).and_return(slack_poster)
    end

    it "barks at all teams" do
      teams.each do |team|
        expect(MessageBuilder).to receive(:new).with(team, :seal).and_return(message_builder)
        expect(SlackPoster).to receive(:new).with(team.channel, anything)
      end

      subject.bark
    end

    context "when in quotes mode" do
      let(:teams) { [lions, cats] }

      it "posts quotes if a quotes day" do
        Timecop.freeze(Time.local(2023, 04, 24)) # Monday
        expect(Message).to receive(:new).with("go lions!").and_return(message)
        expect(SlackPoster).to receive(:new).with(lions.channel, anything)

        subject.bark(mode: "quotes")
      end

      it "doesn't posts quotes if not a quotes day" do
        Timecop.freeze(Time.local(2023, 04, 27)) # Thursday
        expect(Message).not_to receive(:new).with("go lions!")
        expect(SlackPoster).not_to receive(:new).with(lions.channel, anything)

        subject.bark(mode: "quotes")
      end

      it "doesn't posts quotes if unexpected values in quotes days" do
        expect(Message).not_to receive(:new).with("go cats!")
        expect(SlackPoster).not_to receive(:new).with(cats.channel, anything)

        subject.bark(mode: "quotes")
      end

      it "posts quotes if day downcased" do
        Timecop.freeze(Time.local(2023, 04, 25)) # Tuesday
        expect(Message).to receive(:new).with("go lions!").and_return(message)
        expect(SlackPoster).to receive(:new).with(lions.channel, anything)

        subject.bark(mode: "quotes")
      end
    end
  end
end

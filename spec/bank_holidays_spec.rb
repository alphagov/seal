require "spec_helper"
require_relative "../lib/bank_holidays"

RSpec.describe Date do
  before do
    example_bank_holiday_data = {
      "england-and-wales": {
        "division": "england-and-wales",
        "events": [
          {
            "title": "New Year’s Day",
            "date": "2024-01-01",
            "notes": "",
            "bunting": true,
          },
          {
            "title": "Good Friday",
            "date": "2024-03-29",
            "notes": "",
            "bunting": false,
          },
        ],
      },
    }
    stub_request(:get, "https://www.gov.uk/bank-holidays.json")
      .to_return(status: 200, body: example_bank_holiday_data.to_json)
  end

  describe ".bank_holidays" do
    it "returns all bank holidays as an array" do
      expect(Date.bank_holidays).to eq([Date.new(2024, 1, 1), Date.new(2024, 3, 29)])
    end
  end

  describe "#bank_holiday?" do
    it "returns true if the date is a bank holiday" do
      expect(Date.new(2024, 1, 1).bank_holiday?).to eq(true)
    end

    it "returns false if the date is not a bank holiday" do
      expect(Date.new(2018, 3, 28).bank_holiday?).to eq(false)
    end
  end
end

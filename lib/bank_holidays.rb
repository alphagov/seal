require "date"
require "json"
require "net/http"

class Date
  def self.bank_holidays
    @bank_holidays ||= Net::HTTP.get(URI("https://www.gov.uk/bank-holidays.json"))
      .then { JSON.parse _1 }
      .dig("england-and-wales", "events")
      .map { |e| Date.iso8601(e["date"]) }
  rescue StandardError => e
    puts "Error fetching bank holidays JSON: #{e.message}"
    []
  end

  def bank_holiday?
    Date.bank_holidays.include? self
  end
end

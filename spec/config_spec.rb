require "spec_helper"

describe "config/govuk-one-login.yml" do
  it "is valid YAML" do
    config = YAML.load_file("config/govuk-one-login.yml", aliases: true)

    expect(config).to be_a(Hash)
  end
end

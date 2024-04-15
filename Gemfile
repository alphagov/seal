source "https://rubygems.org"

ruby File.read(".ruby-version").chomp

gem "faraday-retry"
gem "octokit"
gem "rubocop-govuk"
gem "slack-poster"

group :test do
  gem "fakefs"
  gem "jsonlint"
  gem "pry-byebug"
  gem "rake"
  gem "rspec"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end

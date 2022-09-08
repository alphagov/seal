source "https://rubygems.org"

ruby File.read(".ruby-version").chomp

gem "octokit", "~> 5.6"
gem "rubocop-govuk", require: false
gem "sinatra"
gem "slack-poster", "~> 1.0.1"
gem "thin"

group :test do
  gem "fakefs"
  gem "jsonlint"
  gem "pry-byebug"
  gem "rake"
  gem "rspec"
  gem "timecop"
end

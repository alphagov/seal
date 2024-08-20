require_relative "lib/validate_repos"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

begin
  require "jsonlint/rake_task"
  JsonLint::RakeTask.new do |t|
    t.paths = %w[
      *.json
    ]
  end
rescue LoadError
  # no jsonlint available
end

begin
  require "rubocop/rake_task"

  RuboCop::RakeTask.new
rescue LoadError
  # no rubocop available
end

desc "Verify that GOVUK repos are tagged #govuk"
task :verify_repo_tags do
  validator = ValidateRepos.new

  untagged_message = <<~UNTAGGED
    The following repos in the repos.yml file in govuk-developer-docs do not have the govuk tag on GitHub:
  UNTAGGED

  falsely_tagged_message = <<~FALSETAG
    The following repos have the govuk tag on GitHub but are not in the repos.yml file in govuk-developer-docs:
  FALSETAG

  puts "#{untagged_message}\n#{validator.untagged_repos}" unless validator.untagged_repos.empty?
  puts "#{falsely_tagged_message}\n#{validator.falsely_tagged_repos}" unless validator.falsely_tagged_repos.empty?

  exit 1 unless validator.untagged_repos.empty? && validator.falsely_tagged_repos.empty?
end

task default: %i[
  jsonlint
  rubocop
  spec
]

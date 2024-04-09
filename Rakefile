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

task default: %i[
  jsonlint
  rubocop
  spec
]

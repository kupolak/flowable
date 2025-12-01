# frozen_string_literal: true

# SimpleCov configuration for test coverage
# Must be required before any application code

require 'simplecov'

SimpleCov.start do
  # Set the coverage directory
  coverage_dir 'coverage'

  # Track all files in lib/
  track_files 'lib/**/*.rb'

  # Add filter to exclude test files
  add_filter '/test/'
  add_filter '/vendor/'
  add_filter 'lib/flowable/version.rb'

  # Group files by type
  add_group 'Client', 'lib/flowable/flowable.rb'
  add_group 'Resources', 'lib/flowable/resources'
  add_group 'DSL', 'lib/flowable/workflow.rb'
  add_group 'Version', 'lib/flowable/version.rb'

  # Minimum coverage percentage (optional - uncomment to enforce)
  # minimum_coverage 80
  # minimum_coverage_by_file 70

  # Enable branch coverage (Ruby 2.5+)
  enable_coverage :branch if respond_to?(:enable_coverage)

  # Merge results from parallel test runs
  use_merging true

  # Set formatter based on environment
  if ENV['CI']
    # For CI: use multiple formatters
    require 'simplecov-cobertura'

    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter
    ])
  else
    # For local development: HTML only
    formatter SimpleCov::Formatter::HTMLFormatter
  end

  # Command name for merging
  command_name "Unit Tests (#{RUBY_VERSION})"
end

# Print coverage summary at exit
SimpleCov.at_exit do
  SimpleCov.result.format!

  if SimpleCov.result.covered_percent < 70
    puts "\n⚠️  Coverage is below 70% (#{SimpleCov.result.covered_percent.round(2)}%)"
  else
    puts "\n✅ Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
  end
end
# 2025-10-15T14:15:32Z - Add complete_and_fetch_next helper
# 2025-11-06T15:19:42Z - Add BPMN task flow example in examples/
# 2025-11-26T12:15:42Z - Update run_tests.sh with instructions
# 2025-10-15T12:15:21Z - Add complete_and_fetch_next helper
# 2025-11-10T11:56:26Z - Add BPMN task flow example in examples/
# 2025-12-03T13:22:42Z - Update run_tests.sh with instructions

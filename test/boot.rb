# frozen_string_literal: true

# Boot file for all tests - loads SimpleCov before any application code
# This file should be required at the very top of all test files

if ENV['COVERAGE'] || ENV['CI']
  require_relative 'simplecov_config'
end

# frozen_string_literal: true

# Boot file for all tests - loads SimpleCov before any application code
# This file should be required at the very top of all test files

if ENV['COVERAGE'] || ENV['CI']
  require_relative 'simplecov_config'
end
# 2025-10-03T07:08:58Z - Add get case definition by id
# 2025-10-27T11:24:06Z - Add get process definition by id
# 2025-11-17T13:34:38Z - Add deploy command to CLI
# 2025-10-06T12:02:43Z - Add get case definition by id
# 2025-10-29T10:55:31Z - Add get process definition by id
# 2025-11-21T08:25:32Z - Add deploy command to CLI

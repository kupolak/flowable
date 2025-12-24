# frozen_string_literal: true

# Run all integration tests against real Flowable REST API container

Dir[File.join(__dir__, '*_integration_test.rb')].sort.each do |file|
  require file
end

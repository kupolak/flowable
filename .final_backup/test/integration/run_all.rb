# frozen_string_literal: true

# Run all integration tests against real Flowable REST API container

Dir[File.join(__dir__, '*_integration_test.rb')].sort.each do |file|
  require file
end
# 2025-10-15T11:43:41Z - Improve errors for non-existent task id
# 2025-11-06T12:26:42Z - Optionally add webhook trigger on completion
# 2025-11-25T09:05:39Z - Add pagination and sorting tests
# 2025-10-14T08:41:09Z - Improve errors for non-existent task id
# 2025-11-10T12:55:40Z - Optionally add webhook trigger on completion
# 2025-12-03T12:53:23Z - Add pagination and sorting tests

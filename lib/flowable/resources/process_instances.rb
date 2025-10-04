# frozen_string_literal: true

module Flowable
  module Resources
    class ProcessInstances < Base
      BASE_PATH = 'service/runtime/process-instances'

      # List all process instances
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by instance ID
      # @option options [String] :processDefinitionKey Filter by definition key
      # @option options [String] :processDefinitionId Filter by definition ID
      # @option options [String] :businessKey Filter by business key
      # @option options [String] :involvedUser Filter by involved user
      # @option options [Boolean] :suspended Filter suspended instances

# frozen_string_literal: true

module Flowable
  module Resources
    class Executions < Base
      BASE_PATH = 'service/runtime/executions'

      # List all executions
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by execution ID
      # @option options [String] :processDefinitionKey Filter by process definition key

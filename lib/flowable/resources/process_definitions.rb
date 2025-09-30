# frozen_string_literal: true

module Flowable
  module Resources
    class ProcessDefinitions < Base
      BASE_PATH = 'service/repository/process-definitions'

      # List all process definitions
      # @param options [Hash] Query parameters
      # @option options [String] :key Filter by key
      # @option options [String] :keyLike Filter by key pattern

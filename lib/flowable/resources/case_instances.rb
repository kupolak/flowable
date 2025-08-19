# frozen_string_literal: true

module Flowable
  module Resources
    class CaseInstances < Base
      BASE_PATH = 'cmmn-runtime/case-instances'

      # List all case instances
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by instance ID
      # @option options [String] :caseDefinitionKey Filter by definition key
      # @option options [String] :caseDefinitionId Filter by definition ID
      # @option options [String] :businessKey Filter by business key
      # @option options [String] :involvedUser Filter by involved user

# frozen_string_literal: true

module Flowable
  module Resources
    class BpmnHistory < Base
      # --- Historic Process Instances ---

      # List historic process instances
      # @param options [Hash] Query parameters
      # @option options [String] :processInstanceId Filter by process instance ID
      # @option options [String] :processDefinitionKey Filter by definition key
      # @option options [String] :processDefinitionId Filter by definition ID
      # @option options [String] :businessKey Filter by business key
      # @option options [String] :involvedUser Filter by involved user
      # @option options [Boolean] :finished Only finished instances
      # @option options [Boolean] :includeProcessVariables Include variables

# frozen_string_literal: true

module Flowable
  module Resources
    class Executions < Base
      BASE_PATH = 'service/runtime/executions'

      # List all executions
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by execution ID
      # @option options [String] :processDefinitionKey Filter by process definition key
      # @option options [String] :processDefinitionId Filter by process definition ID
      # @option options [String] :processInstanceId Filter by process instance ID
      # @option options [String] :activityId Filter by activity ID
      # @option options [String] :parentId Filter by parent execution ID
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of executions
      def list(**options)
        params = paginate_params(options)
        %i[id processDefinitionKey processDefinitionId processInstanceId
           activityId parentId signalEventSubscriptionName
           messageEventSubscriptionName tenantId tenantIdLike].each do |key|

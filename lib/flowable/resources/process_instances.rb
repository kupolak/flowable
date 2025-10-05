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
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of process instances
      def list(**options)
        params = paginate_params(options)
        %i[id processDefinitionKey processDefinitionId businessKey
           involvedUser superProcessInstanceId tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end
        params[:suspended] = options[:suspended] if options.key?(:suspended)
        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)
        params[:includeProcessVariables] = options[:includeProcessVariables] if options.key?(:includeProcessVariables)

        client.get(BASE_PATH, params)
      end


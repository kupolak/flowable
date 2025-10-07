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

      # Get a specific process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Hash] Process instance details
      def get(process_instance_id)
        client.get("#{BASE_PATH}/#{process_instance_id}")
      end

      # Start a new process instance by process definition ID
      # @param process_definition_id [String] The process definition ID
      # @param variables [Hash] Optional variables (name => value)
      # @param business_key [String] Optional business key
      # @param return_variables [Boolean] Return variables in response
      # @return [Hash] Created process instance
      def start_by_id(process_definition_id, variables: {}, business_key: nil, return_variables: false)
        body = { processDefinitionId: process_definition_id }
        body[:businessKey] = business_key if business_key
        body[:variables] = build_variables_array(variables) unless variables.empty?
        body[:returnVariables] = return_variables if return_variables

        client.post(BASE_PATH, body)
      end

      # Start a new process instance by process definition key
      # @param process_definition_key [String] The process definition key
      # @param variables [Hash] Optional variables (name => value)
      # @param business_key [String] Optional business key
      # @param tenant_id [String] Optional tenant ID
      # @param return_variables [Boolean] Return variables in response
      # @return [Hash] Created process instance
      def start_by_key(process_definition_key, variables: {}, business_key: nil, tenant_id: nil,

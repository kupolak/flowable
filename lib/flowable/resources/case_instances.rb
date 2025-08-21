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
      # @option options [Boolean] :includeCaseVariables Include variables in response
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of case instances
      def list(**options)
        params = paginate_params(options)
        %i[id caseDefinitionKey caseDefinitionId businessKey
           involvedUser tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end
        params[:includeCaseVariables] = options[:includeCaseVariables] if options.key?(:includeCaseVariables)
        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get(BASE_PATH, params)
      end

      # Get a specific case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Case instance details
      def get(case_instance_id)
        client.get("#{BASE_PATH}/#{case_instance_id}")
      end

      # Start a new case instance by case definition ID
      # @param case_definition_id [String] The case definition ID
      # @param variables [Hash] Optional variables (name => value)
      # @param business_key [String] Optional business key
      # @param return_variables [Boolean] Return variables in response
      # @return [Hash] Created case instance
      def start_by_id(case_definition_id, variables: {}, business_key: nil, return_variables: false)
        body = { caseDefinitionId: case_definition_id }
        body[:businessKey] = business_key if business_key
        body[:variables] = build_variables_array(variables) unless variables.empty?
        body[:returnVariables] = return_variables if return_variables

        client.post(BASE_PATH, body)
      end

      # Start a new case instance by case definition key
      # @param case_definition_key [String] The case definition key
      # @param variables [Hash] Optional variables (name => value)
      # @param business_key [String] Optional business key
      # @param tenant_id [String] Optional tenant ID
      # @param return_variables [Boolean] Return variables in response
      # @return [Hash] Created case instance
      def start_by_key(case_definition_key, variables: {}, business_key: nil, tenant_id: nil, return_variables: false)
        body = { caseDefinitionKey: case_definition_key }
        body[:businessKey] = business_key if business_key
        body[:tenantId] = tenant_id if tenant_id
        body[:variables] = build_variables_array(variables) unless variables.empty?
        body[:returnVariables] = return_variables if return_variables

        client.post(BASE_PATH, body)
      end

      # Delete a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Boolean] true if successful
      def delete(case_instance_id)
        client.delete("#{BASE_PATH}/#{case_instance_id}")
      end

      # Query case instances with complex filters
      # @param query [Hash] Query body with filters and variable conditions
      # @return [Hash] Paginated list of case instances
      def query(query)
        client.post('query/case-instances', query)
      end

      # Get the diagram/image for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [String] Binary image data
      def diagram(case_instance_id)
        client.get("#{BASE_PATH}/#{case_instance_id}/diagram")
      end

      # Get the stage overview for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Array<Hash>] List of stages with their status
      def stage_overview(case_instance_id)
        client.get("#{BASE_PATH}/#{case_instance_id}/stage-overview")
      end

      # --- Identity Links ---


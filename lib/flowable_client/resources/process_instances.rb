# frozen_string_literal: true

module FlowableClient
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
                       return_variables: false)
        body = { processDefinitionKey: process_definition_key }
        body[:businessKey] = business_key if business_key
        body[:tenantId] = tenant_id if tenant_id
        body[:variables] = build_variables_array(variables) unless variables.empty?
        body[:returnVariables] = return_variables if return_variables

        client.post(BASE_PATH, body)
      end

      # Delete a process instance
      # @param process_instance_id [String] The process instance ID
      # @param delete_reason [String] Reason for deletion
      # @return [Boolean] true if successful
      def delete(process_instance_id, delete_reason: nil)
        params = {}
        params[:deleteReason] = delete_reason if delete_reason
        client.delete("#{BASE_PATH}/#{process_instance_id}", params)
      end

      # Suspend a process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Hash] Updated process instance
      def suspend(process_instance_id)
        client.put("#{BASE_PATH}/#{process_instance_id}", { action: 'suspend' })
      end

      # Activate a suspended process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Hash] Updated process instance
      def activate(process_instance_id)
        client.put("#{BASE_PATH}/#{process_instance_id}", { action: 'activate' })
      end

      # Query process instances with complex filters
      # @param query [Hash] Query body with filters and variable conditions
      # @return [Hash] Paginated list of process instances
      def query(query)
        client.post('service/query/process-instances', query)
      end

      # Get the diagram/image for a process instance
      # @param process_instance_id [String] The process instance ID
      # @return [String] Binary image data
      def diagram(process_instance_id)
        client.get("#{BASE_PATH}/#{process_instance_id}/diagram")
      end

      # --- Identity Links ---

      # Get involved people for a process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Array<Hash>] List of identity links
      def identity_links(process_instance_id)
        client.get("#{BASE_PATH}/#{process_instance_id}/identitylinks")
      end

      # Add an involved user to a process instance
      # @param process_instance_id [String] The process instance ID
      # @param user_id [String] The user ID
      # @param type [String] Type of involvement (e.g., 'participant')
      # @return [Hash] Created identity link
      def add_involved_user(process_instance_id, user_id, type: 'participant')
        client.post(
          "#{BASE_PATH}/#{process_instance_id}/identitylinks",
          { userId: user_id, type: type }
        )
      end

      # Remove an involved user from a process instance
      # @param process_instance_id [String] The process instance ID
      # @param user_id [String] The user ID
      # @param type [String] Type of involvement
      # @return [Boolean] true if successful
      def remove_involved_user(process_instance_id, user_id, type)
        client.delete("#{BASE_PATH}/#{process_instance_id}/identitylinks/users/#{user_id}/#{type}")
      end

      # --- Variables ---

      # Get all variables for a process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Array<Hash>] List of variables
      def variables(process_instance_id)
        client.get("#{BASE_PATH}/#{process_instance_id}/variables")
      end

      # Get a specific variable from a process instance
      # @param process_instance_id [String] The process instance ID
      # @param variable_name [String] The variable name
      # @return [Hash] Variable details
      def variable(process_instance_id, variable_name)
        client.get("#{BASE_PATH}/#{process_instance_id}/variables/#{variable_name}")
      end

      # Create variables on a process instance (fails if exists)
      # @param process_instance_id [String] The process instance ID
      # @param variables [Hash] Variables to create (name => value)
      # @return [Array<Hash>] Created variables
      def create_variables(process_instance_id, variables)
        client.post(
          "#{BASE_PATH}/#{process_instance_id}/variables",
          build_variables_array(variables)
        )
      end

      # Create or update variables on a process instance
      # @param process_instance_id [String] The process instance ID
      # @param variables [Hash] Variables to set (name => value)
      # @return [Array<Hash>] Updated variables
      def set_variables(process_instance_id, variables)
        client.put(
          "#{BASE_PATH}/#{process_instance_id}/variables",
          build_variables_array(variables)
        )
      end

      # Update a single variable on a process instance
      # @param process_instance_id [String] The process instance ID
      # @param name [String] Variable name
      # @param value [Object] Variable value
      # @param type [String] Optional explicit type
      # @return [Hash] Updated variable
      def update_variable(process_instance_id, name, value, type: nil)
        body = { name: name, value: value }
        body[:type] = type || infer_type(value)

        client.put("#{BASE_PATH}/#{process_instance_id}/variables/#{name}", body)
      end

      # Delete a variable from a process instance
      # @param process_instance_id [String] The process instance ID
      # @param variable_name [String] The variable name
      # @return [Boolean] true if successful
      def delete_variable(process_instance_id, variable_name)
        client.delete("#{BASE_PATH}/#{process_instance_id}/variables/#{variable_name}")
      end
    end
  end
end
# 2025-10-02T10:09:12Z - Improve 4xx/5xx error handling for deployments
# 2025-10-24T09:13:54Z - Add bulk deploy endpoint
# 2025-11-14T09:50:53Z - Refactor DSL to Workflow::DSL module
# 2025-10-06T11:41:07Z - Improve 4xx/5xx error handling for deployments
# 2025-10-28T12:05:19Z - Add bulk deploy endpoint
# 2025-11-20T12:45:14Z - Refactor DSL to Workflow::DSL module

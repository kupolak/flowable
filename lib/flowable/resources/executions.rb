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
          params[key] = options[key] if options[key]
        end
        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get(BASE_PATH, params)
      end

      # Get a specific execution
      # @param execution_id [String] The execution ID
      # @return [Hash] Execution details
      def get(execution_id)
        client.get("#{BASE_PATH}/#{execution_id}")
      end

      # Execute an action on an execution
      # @param execution_id [String] The execution ID
      # @param action [String] Action type
      # @param options [Hash] Additional action parameters
      # @return [Hash] Response
      def execute_action(execution_id, action, **options)
        body = { action: action }
        body.merge!(options)
        client.put("#{BASE_PATH}/#{execution_id}", body)
      end

      # Signal an execution
      # @param execution_id [String] The execution ID
      # @param variables [Hash] Optional variables
      # @return [Hash] Response
      def signal(execution_id, variables: {})
        body = { action: 'signal' }
        body[:variables] = build_variables_array(variables) unless variables.empty?
        client.put("#{BASE_PATH}/#{execution_id}", body)
      end

      # Trigger a message event
      # @param execution_id [String] The execution ID
      # @param message_name [String] The message name
      # @param variables [Hash] Optional variables
      # @return [Hash] Response
      def message_event(execution_id, message_name, variables: {})
        body = { action: 'messageEventReceived', messageName: message_name }
        body[:variables] = build_variables_array(variables) unless variables.empty?
        client.put("#{BASE_PATH}/#{execution_id}", body)
      end

      # Trigger a signal event
      # @param execution_id [String] The execution ID
      # @param signal_name [String] The signal name
      # @param variables [Hash] Optional variables
      # @return [Hash] Response
      def signal_event(execution_id, signal_name, variables: {})
        body = { action: 'signalEventReceived', signalName: signal_name }
        body[:variables] = build_variables_array(variables) unless variables.empty?
        client.put("#{BASE_PATH}/#{execution_id}", body)
      end

      # --- Variables ---

      # Get all variables for an execution
      # @param execution_id [String] The execution ID
      # @param scope [String] 'local' or 'global'
      # @return [Array<Hash>] List of variables
      def variables(execution_id, scope: nil)
        params = {}
        params[:scope] = scope if scope
        client.get("#{BASE_PATH}/#{execution_id}/variables", params)
      end

      # Get a specific variable from an execution
      # @param execution_id [String] The execution ID
      # @param variable_name [String] The variable name
      # @param scope [String] 'local' or 'global'
      # @return [Hash] Variable details
      def variable(execution_id, variable_name, scope: nil)
        params = {}
        params[:scope] = scope if scope
        client.get("#{BASE_PATH}/#{execution_id}/variables/#{variable_name}", params)
      end

      # Create variables on an execution
      # @param execution_id [String] The execution ID
      # @param variables [Hash] Variables to create (name => value)
      # @return [Array<Hash>] Created variables
      def create_variables(execution_id, variables)
        client.post("#{BASE_PATH}/#{execution_id}/variables", build_variables_array(variables))
      end

      # Update variables on an execution
      # @param execution_id [String] The execution ID
      # @param variables [Hash] Variables to update (name => value)
      # @return [Array<Hash>] Updated variables
      def update_variables(execution_id, variables)
        client.put("#{BASE_PATH}/#{execution_id}/variables", build_variables_array(variables))
      end

      # Query executions with complex filters
      # @param query [Hash] Query body
      # @return [Hash] Paginated list of executions

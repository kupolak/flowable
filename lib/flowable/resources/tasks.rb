# frozen_string_literal: true

module Flowable
  module Resources
    class Tasks < Base
      BASE_PATH = 'cmmn-runtime/tasks'

      # List all tasks
      # @param options [Hash] Query parameters
      # @option options [String] :name Filter by exact name
      # @option options [String] :nameLike Filter by name pattern
      # @option options [String] :assignee Filter by assignee
      # @option options [String] :owner Filter by owner
      # @option options [String] :candidateUser Tasks claimable by user
      # @option options [String] :candidateGroup Tasks claimable by group
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :caseDefinitionId Filter by case definition
      # @option options [Boolean] :unassigned Only unassigned tasks
      # @option options [Boolean] :active Only active tasks
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of tasks
      def list(**options)
        params = paginate_params(options)
        %i[name nameLike description assignee assigneeLike owner ownerLike
           candidateUser candidateGroup candidateGroups involvedUser
           taskDefinitionKey taskDefinitionKeyLike caseInstanceId
           caseDefinitionId tenantId tenantIdLike category].each do |key|
          params[key] = options[key] if options[key]
        end

        # Integer/Date filters
        params[:priority] = options[:priority] if options[:priority]
        params[:minimumPriority] = options[:minimumPriority] if options[:minimumPriority]
        params[:maximumPriority] = options[:maximumPriority] if options[:maximumPriority]

        # Boolean filters
        %i[unassigned active excludeSubTasks withoutDueDate
           includeTaskLocalVariables withoutTenantId].each do |key|
          params[key] = options[key] if options.key?(key)
        end

        # Date filters
        %i[createdOn createdBefore createdAfter dueOn dueBefore dueAfter].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        client.get(BASE_PATH, params)
      end

      # Get a specific task
      # @param task_id [String] The task ID
      # @return [Hash] Task details
      def get(task_id)
        client.get("#{BASE_PATH}/#{task_id}")
      end

      # Update a task
      # @param task_id [String] The task ID
      # @param attributes [Hash] Attributes to update
      # @option attributes [String] :name Task name
      # @option attributes [String] :description Task description
      # @option attributes [String] :assignee Assignee user ID
      # @option attributes [String] :owner Owner user ID
      # @option attributes [Integer] :priority Priority (default: 50)
      # @option attributes [String] :dueDate Due date (ISO-8601)
      # @option attributes [String] :category Task category
      # @return [Hash] Updated task
      def update(task_id, **attributes)
        body = {}
        %i[name description assignee owner parentTaskId category
           formKey delegationState tenantId].each do |key|
          body[key] = attributes[key] if attributes.key?(key)
        end
        body[:priority] = attributes[:priority] if attributes[:priority]
        body[:dueDate] = format_date(attributes[:dueDate]) if attributes[:dueDate]

        client.put("#{BASE_PATH}/#{task_id}", body)
      end

      # Delete a task
      # @param task_id [String] The task ID
      # @param cascade_history [Boolean] Also delete historic task
      # @param delete_reason [String] Reason for deletion
      # @return [Boolean] true if successful
      def delete(task_id, cascade_history: false, delete_reason: nil)
        params = {}
        params[:cascadeHistory] = cascade_history if cascade_history
        params[:deleteReason] = delete_reason if delete_reason

        client.delete("#{BASE_PATH}/#{task_id}", params)
      end

      # --- Task Actions ---

      # Complete a task
      # @param task_id [String] The task ID
      # @param variables [Hash] Optional variables to set (name => value)
      # @param outcome [String] Optional outcome
      # @return [Hash] Response
      def complete(task_id, variables: {}, outcome: nil)
        body = { action: 'complete' }
        body[:variables] = build_variables_array(variables) unless variables.empty?
        body[:outcome] = outcome if outcome

        client.post("#{BASE_PATH}/#{task_id}", body)
      end

      # Claim a task
      # @param task_id [String] The task ID
      # @param assignee [String] User to assign the task to
      # @return [Hash] Response
      def claim(task_id, assignee)
        client.post("#{BASE_PATH}/#{task_id}", { action: 'claim', assignee: assignee })
      end

      # Unclaim a task (set assignee to null)
      # @param task_id [String] The task ID
      # @return [Hash] Response
      def unclaim(task_id)
        client.post("#{BASE_PATH}/#{task_id}", { action: 'claim', assignee: nil })
      end

      # Delegate a task to another user
      # @param task_id [String] The task ID
      # @param assignee [String] User to delegate to
      # @return [Hash] Response
      def delegate(task_id, assignee)
        client.post("#{BASE_PATH}/#{task_id}", { action: 'delegate', assignee: assignee })
      end

      # Resolve a delegated task
      # @param task_id [String] The task ID
      # @return [Hash] Response
      def resolve(task_id)
        client.post("#{BASE_PATH}/#{task_id}", { action: 'resolve' })
      end

      # --- Variables ---

      # Get all variables for a task
      # @param task_id [String] The task ID
      # @param scope [String] 'local', 'global', or nil for both
      # @return [Array<Hash>] List of variables
      def variables(task_id, scope: nil)
        params = {}
        params[:scope] = scope if scope
        client.get("#{BASE_PATH}/#{task_id}/variables", params)
      end

      # Get a specific variable from a task
      # @param task_id [String] The task ID
      # @param variable_name [String] The variable name
      # @param scope [String] 'local' or 'global'
      # @return [Hash] Variable details
      def variable(task_id, variable_name, scope: nil)
        params = {}
        params[:scope] = scope if scope
        client.get("#{BASE_PATH}/#{task_id}/variables/#{variable_name}", params)
      end

      # Create variables on a task
      # @param task_id [String] The task ID
      # @param variables [Hash] Variables to create (name => value)
      # @param scope [String] 'local' or 'global' (default: local)
      # @return [Array<Hash>] Created variables
      def create_variables(task_id, variables, scope: 'local')
        vars = build_variables_array(variables).map { |v| v.merge(scope: scope) }
        client.post("#{BASE_PATH}/#{task_id}/variables", vars)
      end

      # Set (update or create) variables on a task
      # Updates each variable individually using PUT to /variables/{name}
      # Creates variables that don't exist using POST
      # @param task_id [String] The task ID
      # @param variables [Hash] Variables to set (name => value)
      # @param scope [String] 'local' or 'global' (default: local)

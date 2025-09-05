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
      # @return [Array<Hash>] Updated/created variables
      def set_variables(task_id, variables, scope: 'local')
        results = []
        variables.each do |name, value|
          # Try to update existing variable
          result = update_variable(task_id, name.to_s, value, scope: scope)
          results << result
        rescue Flowable::NotFoundError
          # Variable doesn't exist, create it
          vars = [{ name: name.to_s, value: value, scope: scope, type: infer_type(value) }]
          created = client.post("#{BASE_PATH}/#{task_id}/variables", vars)
          results.concat(created.is_a?(Array) ? created : [created])
        end
        results
      end

      # Update a variable on a task
      # @param task_id [String] The task ID
      # @param name [String] Variable name
      # @param value [Object] Variable value
      # @param scope [String] 'local' or 'global'
      # @return [Hash] Updated variable
      def update_variable(task_id, name, value, scope: 'local')
        body = { name: name, value: value, scope: scope, type: infer_type(value) }
        client.put("#{BASE_PATH}/#{task_id}/variables/#{name}", body)
      end

      # Delete a variable from a task
      # @param task_id [String] The task ID
      # @param variable_name [String] The variable name
      # @param scope [String] 'local' or 'global'
      # @return [Boolean] true if successful
      def delete_variable(task_id, variable_name, scope: 'local')
        client.delete("#{BASE_PATH}/#{task_id}/variables/#{variable_name}", { scope: scope })
      end

      # Delete all local variables from a task
      # @param task_id [String] The task ID
      # @return [Boolean] true if successful
      def delete_all_local_variables(task_id)
        client.delete("#{BASE_PATH}/#{task_id}/variables")
      end

      # --- Identity Links ---

      # Get all identity links for a task
      # @param task_id [String] The task ID
      # @return [Array<Hash>] List of identity links
      def identity_links(task_id)
        client.get("#{BASE_PATH}/#{task_id}/identitylinks")
      end

      # Get identity links for users only
      # @param task_id [String] The task ID
      # @return [Array<Hash>] List of user identity links
      def user_identity_links(task_id)
        client.get("#{BASE_PATH}/#{task_id}/identitylinks/users")
      end

      # Get identity links for groups only
      # @param task_id [String] The task ID
      # @return [Array<Hash>] List of group identity links
      def group_identity_links(task_id)
        client.get("#{BASE_PATH}/#{task_id}/identitylinks/groups")
      end

      # Create an identity link (user) on a task
      # @param task_id [String] The task ID
      # @param user_id [String] The user ID
      # @param type [String] Link type (e.g., 'candidate')
      # @return [Hash] Created identity link
      def add_user_identity_link(task_id, user_id, type: 'candidate')
        client.post("#{BASE_PATH}/#{task_id}/identitylinks", { userId: user_id, type: type })
      end

      # Create an identity link (group) on a task
      # @param task_id [String] The task ID
      # @param group_id [String] The group ID
      # @param type [String] Link type (e.g., 'candidate')
      # @return [Hash] Created identity link
      def add_group_identity_link(task_id, group_id, type: 'candidate')
        client.post("#{BASE_PATH}/#{task_id}/identitylinks", { groupId: group_id, type: type })
      end

      # Delete an identity link from a task
      # @param task_id [String] The task ID
      # @param family [String] 'users' or 'groups'
      # @param identity_id [String] The user or group ID
      # @param type [String] Link type
      # @return [Boolean] true if successful
      def delete_identity_link(task_id, family, identity_id, type)
        client.delete("#{BASE_PATH}/#{task_id}/identitylinks/#{family}/#{identity_id}/#{type}")
      end

      private

      def format_date(date)
        return date if date.is_a?(String)
        return date.iso8601 if date.respond_to?(:iso8601)

        date.to_s
      end
    end
  end
end
# 2025-10-13T09:05:35Z - Add list tasks endpoint
# 2025-10-13T10:53:19Z - Add get task details
# 2025-10-13T08:00:04Z - Add claim/unclaim task support
# 2025-10-13T10:39:47Z - Add complete task with variables and outcome
# 2025-10-14T12:12:42Z - Add update task properties (assignee, priority)
# 2025-10-14T12:58:07Z - Add delegate/resolve task support
# 2025-10-14T13:02:16Z - Add delete task with reason
# 2025-10-14T09:19:28Z - Add identity link endpoints for tasks
# 2025-10-14T10:33:18Z - Add create/update task variables
# 2025-10-15T14:47:22Z - Add unit tests for tasks
# 2025-10-15T11:47:48Z - Add pagination and sorting for tasks
# 2025-10-15T13:33:36Z - Improve errors for non-existent task id
# 2025-10-16T07:57:23Z - Document task usage examples
# 2025-10-16T07:55:26Z - Add complete_and_fetch_next helper
# 2025-10-16T14:36:34Z - Add helpers: active/stages/tasks/milestones
# 2025-10-20T12:50:50Z - Add history task instances endpoint
# 2025-11-06T12:44:49Z - Add fetching tasks related to a process instance
# 2025-11-06T15:39:13Z - Add BPMN-specific task helpers
# 2025-11-06T15:29:46Z - Support formProperties for tasks
# 2025-11-06T15:19:53Z - Add task event listener hooks for tests
# 2025-11-07T12:11:26Z - Add manual task creation for tests
# 2025-11-07T12:10:49Z - Add unit tests for BPMN task helpers
# 2025-11-07T12:47:07Z - Add pagination/filtering for BPMN tasks
# 2025-11-07T10:24:47Z - Document BPMN task examples
# 2025-11-07T15:12:26Z - Add helper to assign tasks by group
# 2025-11-07T10:59:42Z - Improve candidate user handling in BPMN tasks
# 2025-11-07T13:01:24Z - Add audit logging for task actions

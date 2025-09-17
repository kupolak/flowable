# frozen_string_literal: true

module Flowable
  module Resources
    class History < Base
      # --- Historic Case Instances ---

      # List historic case instances
      # @param options [Hash] Query parameters
      # @option options [String] :caseInstanceId Filter by case instance ID
      # @option options [String] :caseDefinitionKey Filter by definition key
      # @option options [String] :caseDefinitionId Filter by definition ID
      # @option options [String] :businessKey Filter by business key
      # @option options [String] :involvedUser Filter by involved user
      # @option options [Boolean] :finished Only finished instances
      # @option options [String] :finishedAfter Finished after date (ISO-8601)
      # @option options [String] :finishedBefore Finished before date (ISO-8601)
      # @option options [String] :startedAfter Started after date
      # @option options [String] :startedBefore Started before date
      # @option options [String] :startedBy Filter by starter user
      # @option options [Boolean] :includeCaseVariables Include variables
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of historic case instances
      def case_instances(**options)
        params = paginate_params(options)
        %i[caseInstanceId caseDefinitionKey caseDefinitionId businessKey
           involvedUser startedBy tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end

        %i[finished includeCaseVariables withoutTenantId].each do |key|
          params[key] = options[key] if options.key?(key)
        end

        %i[finishedAfter finishedBefore startedAfter startedBefore].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        client.get('cmmn-history/historic-case-instances', params)
      end

      # Get a specific historic case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Historic case instance details
      def case_instance(case_instance_id)
        client.get("cmmn-history/historic-case-instances/#{case_instance_id}")
      end

      # Delete a historic case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Boolean] true if successful
      def delete_case_instance(case_instance_id)
        client.delete("cmmn-history/historic-case-instances/#{case_instance_id}")
      end

      # Query historic case instances with complex filters
      # Note: CMMN API doesn't support POST query endpoint, uses GET with parameters
      # @param query [Hash] Query parameters (same as case_instances)
      # @return [Hash] Paginated list of historic case instances
      def query_case_instances(query)
        # Convert query hash to keyword arguments for case_instances
        case_instances(**query.transform_keys(&:to_sym))
      end

      # Get identity links for a historic case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Array<Hash>] List of identity links
      def case_instance_identity_links(case_instance_id)
        client.get("cmmn-history/historic-case-instance/#{case_instance_id}/identitylinks")
      end

      # Get stage overview for a historic case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Array<Hash>] List of stages
      def case_instance_stage_overview(case_instance_id)
        client.get("cmmn-history/historic-case-instances/#{case_instance_id}/stage-overview")
      end

      # --- Historic Milestones ---

      # List historic milestones
      # @param options [Hash] Query parameters
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :caseDefinitionId Filter by case definition
      # @option options [String] :milestoneId Filter by milestone ID
      # @option options [String] :milestoneName Filter by name
      # @option options [String] :reachedBefore Reached before date
      # @option options [String] :reachedAfter Reached after date
      # @return [Hash] Paginated list of milestones
      def milestones(**options)
        params = paginate_params(options)
        %i[caseInstanceId caseDefinitionId milestoneId milestoneName].each do |key|
          params[key] = options[key] if options[key]
        end

        %i[reachedBefore reachedAfter].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        client.get('cmmn-history/historic-milestone-instances', params)
      end

      # Get a specific historic milestone
      # @param milestone_id [String] The milestone instance ID
      # @return [Hash] Milestone details
      def milestone(milestone_id)
        client.get("cmmn-history/historic-milestone-instances/#{milestone_id}")
      end

      # --- Historic Plan Item Instances ---

      # List historic plan item instances
      # @param options [Hash] Query parameters
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :caseDefinitionId Filter by case definition
      # @option options [String] :planItemInstanceId Filter by ID
      # @option options [String] :planItemInstanceName Filter by name
      # @option options [String] :planItemInstanceState Filter by state
      # @option options [String] :stageInstanceId Filter by parent stage
      # @option options [String] :elementId Filter by element ID
      # @option options [String] :planItemDefinitionId Filter by definition ID
      # @option options [String] :planItemDefinitionType Filter by type
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of historic plan item instances
      def plan_item_instances(**options)
        params = paginate_params(options)
        %i[caseInstanceId caseDefinitionId planItemInstanceId planItemInstanceName
           planItemInstanceState stageInstanceId elementId planItemDefinitionId
           planItemDefinitionType referenceId referenceType startUserId tenantId].each do |key|
          params[key] = options[key] if options[key]
        end

        # Date filters - there are many for plan items
        %i[createdBefore createdAfter lastAvailableBefore lastAvailableAfter
           lastEnabledBefore lastEnabledAfter lastDisabledBefore lastDisabledAfter
           lastStartedBefore lastStartedAfter lastSuspendedBefore lastSuspendedAfter
           completedBefore completedAfter terminatedBefore terminatedAfter
           occurredBefore occurredAfter exitBefore exitAfter
           endedBefore endedAfter].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get('cmmn-history/historic-planitem-instances', params)
      end

      # Get a specific historic plan item instance
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Plan item instance details
      def plan_item_instance(plan_item_instance_id)
        client.get("cmmn-history/historic-planitem-instances/#{plan_item_instance_id}")
      end

      # --- Historic Tasks ---

      # List historic task instances
      # @param options [Hash] Query parameters
      # @option options [String] :taskId Filter by task ID
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :caseDefinitionId Filter by case definition
      # @option options [String] :taskName Filter by name
      # @option options [String] :taskNameLike Filter by name pattern
      # @option options [String] :taskAssignee Filter by assignee
      # @option options [String] :taskOwner Filter by owner
      # @option options [String] :taskInvolvedUser Filter by involved user
      # @option options [Boolean] :finished Only finished tasks
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of historic tasks
      def task_instances(**options)
        params = paginate_params(options)
        %i[taskId caseInstanceId caseDefinitionId taskDefinitionKey
           taskName taskNameLike taskDescription taskDescriptionLike
           taskCategory taskDeleteReason taskDeleteReasonLike
           taskAssignee taskAssigneeLike taskOwner taskOwnerLike
           taskInvolvedUser taskPriority parentTaskId tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end

        %i[finished caseFinished withoutDueDate includeTaskLocalVariables withoutTenantId].each do |key|
          params[key] = options[key] if options.key?(key)
        end

        %i[dueDate dueDateAfter dueDateBefore taskCompletedOn taskCompletedAfter
           taskCompletedBefore taskCreatedOn taskCreatedBefore taskCreatedAfter].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        client.get('cmmn-history/historic-task-instances', params)
      end

      # Get a specific historic task
      # @param task_id [String] The task ID
      # @return [Hash] Historic task details
      def task_instance(task_id)
        client.get("cmmn-history/historic-task-instances/#{task_id}")
      end

      # Delete a historic task
      # @param task_id [String] The task ID
      # @return [Boolean] true if successful
      def delete_task_instance(task_id)
        client.delete("cmmn-history/historic-task-instances/#{task_id}")
      end

      # Query historic tasks with complex filters
      # @param query [Hash] Query body
      # @return [Hash] Paginated list of historic tasks
      def query_task_instances(query)
        client.post('query/historic-task-instances', query)
      end

      # Get identity links for a historic task
      # @param task_id [String] The task ID
      # @return [Array<Hash>] List of identity links
      def task_instance_identity_links(task_id)
        client.get("cmmn-history/historic-task-instance/#{task_id}/identitylinks")
      end

      # --- Historic Variables ---

      # List historic variable instances
      # @param options [Hash] Query parameters
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :taskId Filter by task
      # @option options [Boolean] :excludeTaskVariables Exclude task variables
      # @option options [String] :variableName Filter by variable name
      # @option options [String] :variableNameLike Filter by name pattern
      # @return [Hash] Paginated list of historic variables
      def variable_instances(**options)
        params = paginate_params(options)
        %i[caseInstanceId taskId variableName variableNameLike].each do |key|
          params[key] = options[key] if options[key]
        end

        params[:excludeTaskVariables] = options[:excludeTaskVariables] if options.key?(:excludeTaskVariables)

        client.get('cmmn-history/historic-variable-instances', params)
      end


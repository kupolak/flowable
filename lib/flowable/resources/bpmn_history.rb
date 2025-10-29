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
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of historic process instances
      def process_instances(**options)
        params = paginate_params(options)
        %i[processInstanceId processDefinitionKey processDefinitionId businessKey
           involvedUser superProcessInstanceId startedBy tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end

        %i[finished includeProcessVariables withoutTenantId].each do |key|
          params[key] = options[key] if options.key?(key)
        end

        %i[finishedAfter finishedBefore startedAfter startedBefore].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        client.get('service/history/historic-process-instances', params)
      end

      # Get a specific historic process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Hash] Historic process instance details
      def process_instance(process_instance_id)
        client.get("service/history/historic-process-instances/#{process_instance_id}")
      end

      # Delete a historic process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Boolean] true if successful
      def delete_process_instance(process_instance_id)
        client.delete("service/history/historic-process-instances/#{process_instance_id}")
      end

      # Query historic process instances with complex filters
      # @param query [Hash] Query body
      # @return [Hash] Paginated list of historic process instances
      def query_process_instances(query)
        client.post('service/query/historic-process-instances', query)
      end

      # Get identity links for a historic process instance
      # @param process_instance_id [String] The process instance ID
      # @return [Array<Hash>] List of identity links
      def process_instance_identity_links(process_instance_id)
        client.get("service/history/historic-process-instances/#{process_instance_id}/identitylinks")
      end

      # --- Historic Activity Instances ---

      # List historic activity instances
      # @param options [Hash] Query parameters
      # @option options [String] :activityId Filter by activity ID
      # @option options [String] :activityName Filter by activity name
      # @option options [String] :activityType Filter by type (userTask, serviceTask, etc.)
      # @option options [String] :processInstanceId Filter by process instance
      # @option options [String] :processDefinitionId Filter by process definition
      # @option options [Boolean] :finished Only finished activities
      # @return [Hash] Paginated list of historic activities
      def activity_instances(**options)
        params = paginate_params(options)
        %i[activityId activityName activityType processInstanceId processDefinitionId
           executionId taskAssignee tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end

        params[:finished] = options[:finished] if options.key?(:finished)
        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get('service/history/historic-activity-instances', params)
      end

      # Query historic activities with complex filters
      # @param query [Hash] Query body
      # @return [Hash] Paginated list of historic activities
      def query_activity_instances(query)
        client.post('service/query/historic-activity-instances', query)
      end

      # --- Historic Task Instances ---

      # List historic task instances
      # @param options [Hash] Query parameters
      # @option options [String] :taskId Filter by task ID
      # @option options [String] :processInstanceId Filter by process instance
      # @option options [String] :processDefinitionId Filter by process definition
      # @option options [String] :taskName Filter by name
      # @option options [String] :taskAssignee Filter by assignee
      # @option options [Boolean] :finished Only finished tasks
      # @return [Hash] Paginated list of historic tasks
      def task_instances(**options)
        params = paginate_params(options)
        %i[taskId processInstanceId processDefinitionId processDefinitionKey
           taskName taskNameLike taskDescription taskDescriptionLike
           taskDefinitionKey taskDeleteReason taskDeleteReasonLike
           taskAssignee taskAssigneeLike taskOwner taskOwnerLike

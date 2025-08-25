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

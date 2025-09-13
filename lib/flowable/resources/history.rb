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

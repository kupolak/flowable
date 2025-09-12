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

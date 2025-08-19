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

# frozen_string_literal: true

module Flowable
  module Resources
    class CaseDefinitions < Base
      BASE_PATH = 'cmmn-repository/case-definitions'

      # List all case definitions
      # @param options [Hash] Query parameters
      # @option options [String] :key Filter by key
      # @option options [String] :keyLike Filter by key pattern
      # @option options [String] :name Filter by name
      # @option options [String] :nameLike Filter by name pattern
      # @option options [Integer] :version Filter by version
      # @option options [String] :deploymentId Filter by deployment
      # @option options [Boolean] :latest Only return latest versions
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of case definitions
      def list(**options)
        params = paginate_params(options)
        %i[key keyLike name nameLike resourceName resourceNameLike
           category categoryLike categoryNotEquals deploymentId
           startableByUser tenantId].each do |key|
          params[key] = options[key] if options[key]
        end
        params[:version] = options[:version] if options[:version]
        params[:latest] = options[:latest] if options.key?(:latest)
        params[:suspended] = options[:suspended] if options.key?(:suspended)

        client.get(BASE_PATH, params)
      end

      # Get a specific case definition
      # @param case_definition_id [String] The case definition ID
      # @return [Hash] Case definition details
      def get(case_definition_id)
        client.get("#{BASE_PATH}/#{case_definition_id}")
      end

      # Get case definition by key (returns latest version)
      # @param key [String] The case definition key
      # @param tenant_id [String] Optional tenant ID
      # @return [Hash] Case definition details
      def get_by_key(key, tenant_id: nil)
        params = { key: key, latest: true }
        params[:tenantId] = tenant_id if tenant_id

        result = client.get(BASE_PATH, params)
        result['data']&.first
      end

      # Update the category of a case definition
      # @param case_definition_id [String] The case definition ID
      # @param category [String] The new category

# frozen_string_literal: true

module Flowable
  module Resources
    class ProcessDefinitions < Base
      BASE_PATH = 'service/repository/process-definitions'

      # List all process definitions
      # @param options [Hash] Query parameters
      # @option options [String] :key Filter by key
      # @option options [String] :keyLike Filter by key pattern
      # @option options [String] :name Filter by name
      # @option options [String] :nameLike Filter by name pattern
      # @option options [Integer] :version Filter by version
      # @option options [String] :deploymentId Filter by deployment
      # @option options [Boolean] :latest Only return latest versions
      # @option options [Boolean] :suspended Filter by suspension state
      # @option options [String] :tenantId Filter by tenant
      # @return [Hash] Paginated list of process definitions
      def list(**options)
        params = paginate_params(options)
        %i[key keyLike name nameLike resourceName resourceNameLike
           category categoryLike categoryNotEquals deploymentId
           startableByUser tenantId tenantIdLike].each do |key|
          params[key] = options[key] if options[key]
        end
        params[:version] = options[:version] if options[:version]
        params[:latest] = options[:latest] if options.key?(:latest)
        params[:suspended] = options[:suspended] if options.key?(:suspended)
        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get(BASE_PATH, params)
      end

      # Get a specific process definition
      # @param process_definition_id [String] The process definition ID
      # @return [Hash] Process definition details
      def get(process_definition_id)
        client.get("#{BASE_PATH}/#{process_definition_id}")
      end

      # Get process definition by key (returns latest version)
      # @param key [String] The process definition key
      # @param tenant_id [String] Optional tenant ID
      # @return [Hash] Process definition details
      def get_by_key(key, tenant_id: nil)
        params = { key: key, latest: true }
        params[:tenantId] = tenant_id if tenant_id

        result = client.get(BASE_PATH, params)
        result['data']&.first
      end

      # Update the category of a process definition
      # @param process_definition_id [String] The process definition ID

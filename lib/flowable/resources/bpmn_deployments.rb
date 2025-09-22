# frozen_string_literal: true

module Flowable
  module Resources
    class BpmnDeployments < Base
      BASE_PATH = 'service/repository/deployments'

      # List all BPMN deployments
      # @param options [Hash] Query parameters
      # @option options [String] :name Filter by exact name
      # @option options [String] :nameLike Filter by name pattern (use % wildcard)
      # @option options [String] :category Filter by category
      # @option options [String] :tenantId Filter by tenant
      # @option options [Integer] :start Pagination start (default: 0)
      # @option options [Integer] :size Page size (default: 10)
      # @option options [String] :sort Sort field (id/name/deployTime/tenantId)
      # @option options [String] :order Sort order (asc/desc)
      # @return [Hash] Paginated list of deployments
      def list(**options)
        params = paginate_params(options)
        params[:name] = options[:name] if options[:name]
        params[:nameLike] = options[:nameLike] if options[:nameLike]
        params[:category] = options[:category] if options[:category]
        params[:tenantId] = options[:tenantId] if options[:tenantId]
        params[:withoutTenantId] = options[:withoutTenantId] if options[:withoutTenantId]

        client.get(BASE_PATH, params)
      end

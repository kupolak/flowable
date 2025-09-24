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

      # Get a specific deployment
      # @param deployment_id [String] The deployment ID
      # @return [Hash] Deployment details
      def get(deployment_id)
        client.get("#{BASE_PATH}/#{deployment_id}")
      end

      # Create a new deployment from a file
      # @param file_path [String] Path to BPMN file (.bpmn, .bpmn20.xml, .bar, .zip)
      # @param name [String] Optional deployment name
      # @param tenant_id [String] Optional tenant ID
      # @param category [String] Optional category
      # @return [Hash] Created deployment
      def create(file_path, name: nil, tenant_id: nil, category: nil)
        additional_fields = {}
        additional_fields[:deploymentName] = name if name
        additional_fields[:tenantId] = tenant_id if tenant_id
        additional_fields[:category] = category if category

        client.post_multipart(BASE_PATH, file_path, additional_fields)
      end

      # Delete a deployment
      # @param deployment_id [String] The deployment ID
      # @param cascade [Boolean] Also delete running process instances
      # @return [Boolean] true if successful
      def delete(deployment_id, cascade: false)

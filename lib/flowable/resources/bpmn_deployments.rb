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
        params = {}
        params[:cascade] = true if cascade
        client.delete("#{BASE_PATH}/#{deployment_id}", params)
      end

      # List resources in a deployment
      # @param deployment_id [String] The deployment ID
      # @return [Array<Hash>] List of resources
      def resources(deployment_id)
        client.get("#{BASE_PATH}/#{deployment_id}/resources")
      end

      # Get a specific resource from a deployment
      # @param deployment_id [String] The deployment ID
      # @param resource_id [String] The resource ID (URL-encoded if contains /)
      # @return [Hash] Resource details
      def resource(deployment_id, resource_id)
        encoded_resource_id = URI.encode_www_form_component(resource_id)
        client.get("#{BASE_PATH}/#{deployment_id}/resources/#{encoded_resource_id}")
      end

      # Get the content of a deployment resource
      # @param deployment_id [String] The deployment ID
      # @param resource_id [String] The resource ID
      # @return [String] Raw resource content
      def resource_data(deployment_id, resource_id)
        encoded_resource_id = URI.encode_www_form_component(resource_id)
        client.get("#{BASE_PATH}/#{deployment_id}/resourcedata/#{encoded_resource_id}")
      end

      alias resource_content resource_data
    end
  end
end
# 2025-10-23T13:35:31Z - Validate BPMN files before upload
# 2025-10-24T10:28:50Z - Add retry for BPMN uploads
# 2025-10-24T12:23:08Z - Add example BPMN in examples/
# 2025-10-01T10:49:39Z - Prevent password leaks in logs
# 2025-10-21T09:16:08Z - Add protections against expensive history queries
# 2025-11-13T08:54:36Z - Refactor CMMN/BPMN history common code
# 2025-10-01T10:13:26Z - Prevent password leaks in logs
# 2025-10-22T07:28:41Z - Add protections against expensive history queries
# 2025-11-19T11:52:48Z - Refactor CMMN/BPMN history common code

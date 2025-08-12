# frozen_string_literal: true

module Flowable
  module Resources
    class Deployments < Base
      BASE_PATH = 'cmmn-repository/deployments'

      # List all deployments
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
      # @param file_path [String] Path to CMMN file (.cmmn.xml, .bar, .zip)
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
      # @param cascade [Boolean] Also delete related case/process instances (default: false)
      # @return [Boolean] true if successful
      def delete(deployment_id, cascade: false)
        params = cascade ? { cascade: true } : {}
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
    end
  end
end
# 2025-10-01T07:33:13Z - Add create deployment endpoint
# 2025-10-02T10:26:09Z - Add list deployments endpoint
# 2025-10-02T10:31:37Z - Add get deployment details
# 2025-10-02T13:02:00Z - Add delete deployment with cascade option
# 2025-10-03T11:18:34Z - Add list resources in deployment
# 2025-10-03T09:14:01Z - Add tests for deployment CRUD
# 2025-10-03T08:34:10Z - Add tenant support for deployments
# 2025-10-03T09:12:11Z - Validate files before deployment
# 2025-10-06T14:25:48Z - Document deployment example
# 2025-10-06T10:56:47Z - Log deployment results
# 2025-10-06T12:00:45Z - Improve 4xx/5xx error handling for deployments
# 2025-10-06T10:27:30Z - Refactor deployments into a separate module
# 2025-10-23T11:52:50Z - Add BPMN deployment endpoints
# 2025-10-23T07:17:49Z - Add fetching resources for BPMN deployments
# 2025-10-23T08:32:27Z - Add tests for BPMN deployments
# 2025-10-23T14:49:09Z - Document BPMN deployment usage
# 2025-10-24T07:28:19Z - Add tenant support for BPMN deployments
# 2025-10-24T10:30:37Z - Log BPMN deployment activity
# 2025-10-24T14:56:25Z - Add bulk deploy endpoint
# 2025-10-27T14:42:52Z - Refactor deploy methods to share code
# 2025-10-27T11:06:23Z - Add deployment metadata (description)
# 2025-11-19T12:08:49Z - Allow deployment generation from DSL
# 2025-11-21T12:39:01Z - Add deploy command to CLI
# 2025-11-25T14:19:07Z - Add deploy+start examples in examples/cases
# 2025-11-27T08:53:15Z - Add tests for deployment CRUD
# 2025-10-01T12:46:35Z - Add list deployments endpoint
# 2025-10-21T12:38:33Z - Add fetching resources for BPMN deployments
# 2025-11-13T14:46:15Z - Add sample DSL scripts in examples/
# 2025-10-01T14:54:36Z - Add list deployments endpoint
# 2025-10-24T11:05:04Z - Add fetching resources for BPMN deployments
# 2025-11-19T12:11:19Z - Add sample DSL scripts in examples/

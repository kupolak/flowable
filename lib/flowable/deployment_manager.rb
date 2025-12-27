# frozen_string_literal: true

module Flowable
  # Deployment Manager for BPMN processes
  # Provides high-level interface for deploying and managing BPMN process definitions
  class DeploymentManager
    class << self
      # Deploy a BPMN process file to Flowable
      # @param file_path [String] Path to BPMN file
      # @param name [String] Optional deployment name
      # @param category [String] Optional category
      # @param tenant_id [String] Optional tenant ID
      # @return [Hash] Deployment info with process definitions
      def deploy(file_path, name: nil, category: nil, tenant_id: nil)
        raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

        deployment_name = name || File.basename(file_path, '.*')

        deployment = FlowableClient.bpmn_deployments.create(
          file_path,
          name: deployment_name,
          category: category,
          tenant_id: tenant_id
        )

        # Fetch process definitions from this deployment
        process_defs = FlowableClient.process_definitions.list(
          deploymentId: deployment['id']
        )

        {
          deployment: deployment,
          process_definitions: process_defs['data'] || []
        }
      end

      # Undeploy (delete) a deployment
      # @param deployment_id [String] Deployment ID to delete
      # @param cascade [Boolean] Delete running process instances
      # @return [Boolean] true if successful
      def undeploy(deployment_id, cascade: false)
        FlowableClient.bpmn_deployments.delete(deployment_id, cascade: cascade)
        true
      rescue Flowable::ApiError => e
        raise DeploymentError, "Failed to undeploy: #{e.message}"
      end

      # List all deployments with their process definitions
      # @param options [Hash] Query options (name, category, etc.)
      # @return [Array<Hash>] List of deployments with process info
      def list_deployments(**options)
        result = FlowableClient.bpmn_deployments.list(**options)
        deployments = result['data'] || []

        deployments.map do |deployment|
          process_defs = FlowableClient.process_definitions.list(
            deploymentId: deployment['id']
          )

          deployment.merge(
            'processDefinitions' => process_defs['data'] || []
          )
        end
      end

      # Find deployments by process definition key
      # @param process_key [String] Process definition key
      # @return [Array<Hash>] Matching deployments
      def find_by_process_key(process_key)
        process_defs = FlowableClient.process_definitions.list(key: process_key)
        deployment_ids = (process_defs['data'] || []).map { |pd| pd['deploymentId'] }.uniq

        deployment_ids.map do |dep_id|
          FlowableClient.bpmn_deployments.get(dep_id)
        end
      end

      # Get deployment details with resources
      # @param deployment_id [String] Deployment ID
      # @return [Hash] Deployment with resources
      def get_deployment(deployment_id)
        deployment = FlowableClient.bpmn_deployments.get(deployment_id)
        resources = FlowableClient.bpmn_deployments.resources(deployment_id)
        process_defs = FlowableClient.process_definitions.list(
          deploymentId: deployment_id
        )

        deployment.merge(
          'resources' => resources,
          'processDefinitions' => process_defs['data'] || []
        )
      end

      # Redeploy a BPMN file (delete old and deploy new)
      # @param process_key [String] Process definition key to replace
      # @param file_path [String] New BPMN file path
      # @param cascade [Boolean] Delete running instances of old version
      # @return [Hash] New deployment info
      def redeploy(process_key, file_path, cascade: false)
        # Find and delete old deployments
        old_deployments = find_by_process_key(process_key)
        old_deployments.each do |dep|
          undeploy(dep['id'], cascade: cascade)
        end

        # Deploy new version
        deploy(file_path, name: "#{process_key}_redeploy")
      end

      # Get BPMN XML content from deployment
      # @param deployment_id [String] Deployment ID
      # @param resource_id [String] Resource ID (usually the .bpmn20.xml filename)
      # @return [String] BPMN XML content
      def get_bpmn_xml(deployment_id, resource_id)
        FlowableClient.bpmn_deployments.resource_data(deployment_id, resource_id)
      end
    end

    class DeploymentError < StandardError; end
  end
end

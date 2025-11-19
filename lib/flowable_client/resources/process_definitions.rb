# frozen_string_literal: true

module FlowableClient
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
      # @param category [String] The new category
      # @return [Hash] Updated process definition
      def update_category(process_definition_id, category)
        client.put("#{BASE_PATH}/#{process_definition_id}", { category: category })
      end

      # Suspend a process definition
      # @param process_definition_id [String] The process definition ID
      # @param include_instances [Boolean] Also suspend running instances
      # @param date [String] Effective date (ISO-8601)
      # @return [Hash] Updated process definition
      def suspend(process_definition_id, include_instances: false, date: nil)
        body = { action: 'suspend', includeProcessInstances: include_instances }
        body[:date] = date if date
        client.put("#{BASE_PATH}/#{process_definition_id}", body)
      end

      # Activate a process definition
      # @param process_definition_id [String] The process definition ID
      # @param include_instances [Boolean] Also activate suspended instances
      # @param date [String] Effective date (ISO-8601)
      # @return [Hash] Updated process definition
      def activate(process_definition_id, include_instances: false, date: nil)
        body = { action: 'activate', includeProcessInstances: include_instances }
        body[:date] = date if date
        client.put("#{BASE_PATH}/#{process_definition_id}", body)
      end

      # Get the BPMN XML content of a process definition
      # @param process_definition_id [String] The process definition ID
      # @return [String] BPMN XML content
      def resource_data(process_definition_id)
        client.get("#{BASE_PATH}/#{process_definition_id}/resourcedata")
      end

      alias resource_content resource_data

      # Get the BPMN model as JSON
      # @param process_definition_id [String] The process definition ID
      # @return [Hash] BPMN model structure
      def model(process_definition_id)
        client.get("#{BASE_PATH}/#{process_definition_id}/model")
      end

      # Get process diagram image (PNG)
      # @param process_definition_id [String] The process definition ID
      # @return [String] Binary image data
      def diagram(process_definition_id)
        client.get("#{BASE_PATH}/#{process_definition_id}/image")
      end

      alias image diagram

      # Get all candidate starters for a process definition
      # @param process_definition_id [String] The process definition ID
      # @return [Array<Hash>] List of identity links
      def identity_links(process_definition_id)
        client.get("#{BASE_PATH}/#{process_definition_id}/identitylinks")
      end

      # Add a candidate starter (user) to a process definition
      # @param process_definition_id [String] The process definition ID
      # @param user_id [String] The user ID
      # @return [Hash] Created identity link
      def add_candidate_user(process_definition_id, user_id)
        client.post("#{BASE_PATH}/#{process_definition_id}/identitylinks", { user: user_id })
      end

      # Add a candidate starter (group) to a process definition
      # @param process_definition_id [String] The process definition ID
      # @param group_id [String] The group ID
      # @return [Hash] Created identity link
      def add_candidate_group(process_definition_id, group_id)
        client.post("#{BASE_PATH}/#{process_definition_id}/identitylinks", { group: group_id })
      end

      # Remove a candidate starter from a process definition
      # @param process_definition_id [String] The process definition ID
      # @param family [String] 'users' or 'groups'
      # @param identity_id [String] The user or group ID
      # @return [Boolean] true if successful
      def remove_candidate(process_definition_id, family, identity_id)
        client.delete("#{BASE_PATH}/#{process_definition_id}/identitylinks/#{family}/#{identity_id}")
      end
    end
  end
end
# 2025-10-02T14:40:00Z - Log deployment results
# 2025-10-24T12:17:32Z - Improve 400 handling for invalid files
# 2025-11-14T12:17:09Z - Integrate DSL with workflow.rb core
# 2025-10-03T09:28:25Z - Log deployment results
# 2025-10-27T14:12:52Z - Improve 400 handling for invalid files
# 2025-11-20T15:14:19Z - Integrate DSL with workflow.rb core

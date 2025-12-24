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
      # @return [Hash] Updated case definition
      def update_category(case_definition_id, category)
        client.put("#{BASE_PATH}/#{case_definition_id}", { category: category })
      end

      # Get the CMMN XML content of a case definition
      # @param case_definition_id [String] The case definition ID
      # @return [String] CMMN XML content
      def resource_data(case_definition_id)
        client.get("#{BASE_PATH}/#{case_definition_id}/resourcedata")
      end

      alias resource_content resource_data

      # Get the CMMN model as JSON
      # @param case_definition_id [String] The case definition ID
      # @return [Hash] CMMN model structure
      def model(case_definition_id)
        client.get("#{BASE_PATH}/#{case_definition_id}/model")
      end

      # Get all candidate starters for a case definition
      # @param case_definition_id [String] The case definition ID
      # @return [Array<Hash>] List of identity links
      def identity_links(case_definition_id)
        client.get("#{BASE_PATH}/#{case_definition_id}/identitylinks")
      end

      # Add a candidate starter (user) to a case definition
      # @param case_definition_id [String] The case definition ID
      # @param user_id [String] The user ID
      # @return [Hash] Created identity link
      def add_candidate_user(case_definition_id, user_id)
        client.post(
          "#{BASE_PATH}/#{case_definition_id}/identitylinks",
          { user: user_id }
        )
      end

      # Add a candidate starter (group) to a case definition
      # @param case_definition_id [String] The case definition ID
      # @param group_id [String] The group ID
      # @return [Hash] Created identity link
      def add_candidate_group(case_definition_id, group_id)
        client.post(
          "#{BASE_PATH}/#{case_definition_id}/identitylinks",
          { groupId: group_id }
        )
      end

      # Remove a candidate starter from a case definition
      # @param case_definition_id [String] The case definition ID
      # @param family [String] 'users' or 'groups'
      # @param identity_id [String] The user or group ID
      # @return [Boolean] true if successful
      def remove_candidate(case_definition_id, family, identity_id)
        client.delete("#{BASE_PATH}/#{case_definition_id}/identitylinks/#{family}/#{identity_id}")
      end
    end
  end
end

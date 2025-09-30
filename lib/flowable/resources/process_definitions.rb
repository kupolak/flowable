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

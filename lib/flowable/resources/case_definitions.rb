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

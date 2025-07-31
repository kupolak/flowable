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

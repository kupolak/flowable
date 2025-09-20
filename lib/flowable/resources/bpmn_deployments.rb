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

# frozen_string_literal: true

module Flowable
  module Resources
    class PlanItemInstances < Base
      BASE_PATH = 'cmmn-runtime/plan-item-instances'

      # List all plan item instances
      # @param options [Hash] Query parameters
      # @option options [String] :id Filter by ID
      # @option options [String] :caseDefinitionId Filter by case definition
      # @option options [String] :caseInstanceId Filter by case instance
      # @option options [String] :stageInstanceId Filter by parent stage
      # @option options [String] :planItemDefinitionId Filter by plan item definition
      # @option options [String] :planItemDefinitionType Filter by type (stage, milestone, humanTask, etc.)
      # @option options [String] :planItemDefinitionTypes Comma-separated types
      # @option options [String] :state Filter by state (available, active, enabled, disabled, completed, etc.)
      # @option options [String] :name Filter by name
      # @option options [String] :elementId Filter by element ID from model
      # @option options [String] :tenantId Filter by tenant

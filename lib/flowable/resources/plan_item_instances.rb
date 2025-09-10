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
      # @return [Hash] Paginated list of plan item instances
      def list(**options)
        params = paginate_params(options)
        %i[id caseDefinitionId caseInstanceId stageInstanceId
           planItemDefinitionId planItemDefinitionType planItemDefinitionTypes
           state name elementId referenceId referenceType
           startUserId tenantId].each do |key|
          params[key] = options[key] if options[key]
        end

        # Date filters
        %i[createdBefore createdAfter].each do |key|
          params[key] = format_date(options[key]) if options[key]
        end

        params[:withoutTenantId] = options[:withoutTenantId] if options.key?(:withoutTenantId)

        client.get(BASE_PATH, params)
      end

      # Get a specific plan item instance
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Plan item instance details
      def get(plan_item_instance_id)
        client.get("#{BASE_PATH}/#{plan_item_instance_id}")
      end

      # Execute an action on a plan item instance
      # @param plan_item_instance_id [String] The plan item instance ID
      # @param action [String] Action to execute
      # @return [Hash] Response
      def execute_action(plan_item_instance_id, action)
        client.put("#{BASE_PATH}/#{plan_item_instance_id}", { action: action })
      end

      # Start a plan item (must be in enabled state)
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Response
      def start(plan_item_instance_id)
        execute_action(plan_item_instance_id, 'start')
      end

      # Trigger a plan item (for items waiting for trigger)
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Response
      def trigger(plan_item_instance_id)
        execute_action(plan_item_instance_id, 'trigger')
      end

      # Enable a plan item (must be currently disabled)
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Response
      def enable(plan_item_instance_id)
        execute_action(plan_item_instance_id, 'enable')
      end

      # Disable a plan item (must be currently enabled)
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Response
      def disable(plan_item_instance_id)
        execute_action(plan_item_instance_id, 'disable')
      end

      # Evaluate criteria on a plan item
      # @param plan_item_instance_id [String] The plan item instance ID
      # @return [Hash] Response
      def evaluate_criteria(plan_item_instance_id)
        execute_action(plan_item_instance_id, 'evaluateCriteria')
      end


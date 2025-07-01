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

      # --- Helper methods ---

      # List all active plan items for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Paginated list of active plan items
      def active_for_case(case_instance_id)
        list(caseInstanceId: case_instance_id, state: 'active')
      end

      # List all stages for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Paginated list of stages
      def stages_for_case(case_instance_id)
        list(caseInstanceId: case_instance_id, planItemDefinitionType: 'stage')
      end

      # List all human tasks for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Paginated list of human tasks
      def human_tasks_for_case(case_instance_id)
        list(caseInstanceId: case_instance_id, planItemDefinitionType: 'humantask')
      end

      # List all milestones for a case instance
      # @param case_instance_id [String] The case instance ID
      # @return [Hash] Paginated list of milestones
      def milestones_for_case(case_instance_id)
        list(caseInstanceId: case_instance_id, planItemDefinitionType: 'milestone')
      end

      private

      def format_date(date)
        return date if date.is_a?(String)
        return date.iso8601 if date.respond_to?(:iso8601)

        date.to_s
      end
    end
  end
end
# 2025-10-16T08:01:23Z - Add list plan item instances
# 2025-10-16T13:56:59Z - Add get single plan item
# 2025-10-17T13:20:18Z - Add integration tests for plan items
# 2025-10-17T13:23:57Z - Document plan item helpers
# 2025-10-17T10:15:50Z - Add pagination for plan items
# 2025-10-17T14:04:33Z - Add examples for plan items in examples/
# 2025-10-17T14:22:21Z - Add bulk actions endpoint for plan items
# 2025-10-20T14:25:21Z - Improve action logging for plan items
# 2025-10-20T07:49:15Z - Refactor plan_item_instances module
# 2025-10-20T13:38:50Z - Add history plan item instances endpoint
# 2025-10-02T12:30:04Z - Add list resources in deployment
# 2025-10-23T13:37:46Z - Document BPMN deployment usage
# 2025-11-13T09:34:33Z - Add unit tests for DSL parsing
# 2025-10-02T10:54:17Z - Add list resources in deployment
# 2025-10-24T13:34:53Z - Document BPMN deployment usage
# 2025-11-19T15:23:56Z - Add unit tests for DSL parsing

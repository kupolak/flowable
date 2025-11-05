# frozen_string_literal: true

require_relative '../flowable'

module Flowable
  # High-level DSL for workflow management
  # Provides a more intuitive API for common workflow operations
  module Workflow
    class Case
      attr_reader :client
      attr_reader :case_key
      attr_reader :instance

      def initialize(client, case_key)
        @client = client
        @case_key = case_key
        @instance = nil
        @task_handlers = {}
        @milestone_callbacks = {}
      end

      # Start a new case instance
      # @param variables [Hash] Initial variables
      # @param business_key [String] Business key
      # @return [self]
      def start(variables: {}, business_key: nil)
        @instance = client.case_instances.start_by_key(
          case_key,
          variables: variables,
          business_key: business_key,
          return_variables: true
        )
        self
      end

      # Load an existing case instance
      # @param case_instance_id [String] Case instance ID
      # @return [self]
      def load(case_instance_id)
        @instance = client.case_instances.get(case_instance_id)
        self
      end

      # Find case by business key
      # @param business_key [String] Business key
      # @return [self, nil]
      def find_by_business_key(business_key)
        result = client.case_instances.list(
          caseDefinitionKey: case_key,
          businessKey: business_key,
          size: 1
        )
        return nil if result['data'].empty?

        @instance = result['data'].first
        self
      end

      # Get case instance ID
      def id
        instance&.dig('id')
      end

      # Get case state
      def state
        refresh! if instance
        instance&.dig('state')
      end

      # Check if case is active
      def active?
        state == 'active'
      end

      # Check if case is completed
      def completed?
        instance&.dig('ended') == true || instance&.dig('completed') == true
      end

      # Refresh case instance data from server
      def refresh!
        @instance = client.case_instances.get(id) if id
        self
      end

      # Get all variables
      def variables
        return {} unless id

        client.case_instances.variables(id).each_with_object({}) do |var, hash|
          hash[var['name'].to_sym] = var['value']
        end
      end

      # Get a single variable
      def [](name)
        variables[name.to_sym]
      end

      # Set variables
      def []=(name, value)
        set(name => value)
      end

      # Set multiple variables
      def set(vars)
        client.case_instances.set_variables(id, vars)
        self
      end

      # Get stage overview
      def stages
        return [] unless id

        client.case_instances.stage_overview(id).map do |stage|
          Stage.new(stage)
        end
      end

      # Get current stage
      def current_stage
        stages.find(&:current?)
      end

      # Get all tasks for this case
      def tasks
        return [] unless id

        result = client.tasks.list(caseInstanceId: id)
        result['data'].map { |t| Task.new(client, t) }
      end

      # Get pending tasks (unassigned or assigned to current user)
      def pending_tasks
        tasks.reject(&:completed?)
      end

      # Find task by name
      def task(name)
        tasks.find { |t| t.name == name }
      end

      # Wait for a task to appear (polling)
      # @param name [String] Task name
      # @param timeout [Integer] Timeout in seconds
      # @param interval [Integer] Poll interval in seconds
      # @yield [Task] Block to execute when task is found
      def wait_for_task(name, timeout: 30, interval: 1)
        start_time = Time.now
        loop do
          task = self.task(name)
          if task
            yield task if block_given?
            return task
          end

          if Time.now - start_time > timeout
            raise Error, "Timeout waiting for task '#{name}'"
          end

          sleep interval
          refresh!
        end
      end

      # Register a task handler
      # @param task_name [String] Task name to handle
      # @yield [Task] Block to execute when task is available

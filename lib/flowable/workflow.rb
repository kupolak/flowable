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
      def on_task(task_name, &block)
        @task_handlers[task_name] = block
        self
      end

      # Process all pending tasks with registered handlers
      def process_tasks!
        pending_tasks.each do |task|
          handler = @task_handlers[task.name]
          handler&.call(task)
        end
        self
      end

      # Delete the case instance
      def delete!
        client.case_instances.delete(id) if id
        @instance = nil
      end

      # Get identity links
      def involved_users
        return [] unless id

        client.case_instances.identity_links(id)
      end

      # Add involved user
      def involve(user_id, type: 'participant')
        client.case_instances.add_involved_user(id, user_id, type: type)
        self
      end
    end

    class Process
      attr_reader :client
      attr_reader :process_key
      attr_reader :instance

      def initialize(client, process_key)
        @client = client
        @process_key = process_key
        @instance = nil
      end

      # Start a new process instance
      def start(variables: {}, business_key: nil)
        @instance = client.process_instances.start_by_key(
          process_key,
          variables: variables,
          business_key: business_key,
          return_variables: true
        )
        self
      end

      # Load an existing process instance
      def load(process_instance_id)
        @instance = client.process_instances.get(process_instance_id)
        self
      end

      def id
        instance&.dig('id')
      end

      def ended?
        instance&.dig('ended') == true
      end

      def suspended?
        instance&.dig('suspended') == true
      end

      def refresh!
        @instance = client.process_instances.get(id) if id
        self
      end

      def variables
        return {} unless id

        client.process_instances.variables(id).each_with_object({}) do |var, hash|
          hash[var['name'].to_sym] = var['value']
        end
      end

      def set(vars)
        client.process_instances.set_variables(id, vars)
        self
      end

      def suspend!
        client.process_instances.suspend(id)
        refresh!
      end

      def activate!
        client.process_instances.activate(id)
        refresh!
      end

      def delete!(reason: nil)
        client.process_instances.delete(id, delete_reason: reason)
        @instance = nil
      end
    end

    class Task
      attr_reader :client
      attr_reader :data

      def initialize(client, data)
        @client = client
        @data = data
      end

      def id
        data['id']
      end

      def name
        data['name']
      end

      def description
        data['description']
      end

      def assignee
        data['assignee']
      end

      def owner
        data['owner']
      end

      def priority
        data['priority']
      end

      def due_date
        data['dueDate']
      end

      def created_at
        data['createTime']
      end

      def case_instance_id
        data['caseInstanceId']
      end

      def process_instance_id
        data['processInstanceId']
      end

      def completed?
        !data['endTime'].nil? && !data['endTime'].to_s.empty?
      end

      def assigned?
        !assignee.nil?
      end

      # Claim the task
      def claim(user)
        client.tasks.claim(id, user)
        @data['assignee'] = user
        self
      end

      # Unclaim the task
      def unclaim
        client.tasks.unclaim(id)
        @data['assignee'] = nil
        self
      end

      # Complete the task
      def complete(variables: {}, outcome: nil)
        client.tasks.complete(id, variables: variables, outcome: outcome)
        self
      end

      # Delegate to another user
      def delegate_to(user)
        client.tasks.delegate(id, user)
        self
      end

      # Resolve delegated task
      def resolve
        client.tasks.resolve(id)
        self
      end

      # Get task variables
      def variables(scope: nil)
        client.tasks.variables(id, scope: scope).each_with_object({}) do |var, hash|
          hash[var['name'].to_sym] = var['value']
        end
      end

      # Set task variables
      def set(vars, scope: 'local')
        vars.each do |name, value|
          client.tasks.update_variable(id, name.to_s, value, scope: scope)
        end
        self
      end

      # Update task properties
      def update(attrs)
        client.tasks.update(id, **attrs)
        attrs.each { |k, v| @data[k.to_s] = v }
        self
      end

      # Add candidate user
      def add_candidate(user_id)
        client.tasks.add_user_identity_link(id, user_id, type: 'candidate')
        self
      end

      # Add candidate group
      def add_candidate_group(group_id)
        client.tasks.add_group_identity_link(id, group_id, type: 'candidate')
        self
      end
    end

    class Stage
      attr_reader :data

      def initialize(data)
        @data = data
      end

      def id

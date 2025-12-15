#!/usr/bin/env ruby
# frozen_string_literal: true

# Example usage of Flowable
# Run Flowable REST first: docker run -p 8080:8080 flowable/flowable-rest

require_relative '../lib/flowable'

# Initialize the client
client = Flowable::Client.new(
  host: 'localhost',
  port: 8080,
  username: 'rest-admin',
  password: 'test'
)

puts '=== Flowable CMMN Client Examples ==='
puts

# ============================================
# 1. DEPLOYMENTS
# ============================================
puts '--- Deployments ---'

# List all deployments
deployments = client.deployments.list
puts "Found #{deployments['total']} deployments"

# Deploy a CMMN file (uncomment when you have a file)
# deployment = client.deployments.create('/path/to/my-case.cmmn.xml')
# puts "Created deployment: #{deployment['id']}"

# ============================================
# 2. CASE DEFINITIONS
# ============================================
puts "\n--- Case Definitions ---"

# List all case definitions
definitions = client.case_definitions.list
puts "Found #{definitions['total']} case definitions"

definitions['data'].each do |defn|
  puts "  - #{defn['name']} (key: #{defn['key']}, version: #{defn['version']})"
end

# Get latest version by key
# latest = client.case_definitions.get_by_key('myCase')
# puts "Latest version: #{latest['version']}" if latest

# ============================================
# 3. CASE INSTANCES
# ============================================
puts "\n--- Case Instances ---"

# List all case instances
instances = client.case_instances.list
puts "Found #{instances['total']} case instances"

# Start a new case instance by key
# case_instance = client.case_instances.start_by_key(
#   'myCase',
#   variables: {
#     customerName: 'John Doe',
#     amount: 1000,
#     approved: false
#   },
#   business_key: 'ORDER-12345'
# )
# puts "Started case: #{case_instance['id']}"

# Start by definition ID
# case_instance = client.case_instances.start_by_id(
#   'some-definition-id',
#   variables: { foo: 'bar' }
# )

# Get case instance details
# instance = client.case_instances.get('case-instance-id')
# puts "Case state: #{instance['state']}"

# Get stage overview
# stages = client.case_instances.stage_overview('case-instance-id')
# stages.each do |stage|
#   status = stage['current'] ? '[CURRENT]' : (stage['ended'] ? '[DONE]' : '[PENDING]')
#   puts "  #{status} #{stage['name']}"
# end

# ============================================
# 4. VARIABLES
# ============================================
puts "\n--- Variables ---"

# Get variables for a case instance
# vars = client.case_instances.variables('case-instance-id')
# vars.each do |var|
#   puts "  #{var['name']} = #{var['value']} (#{var['type']})"
# end

# Set/update variables
# client.case_instances.set_variables('case-instance-id', {
#   status: 'processing',
#   updatedAt: Time.now.iso8601
# })

# Update single variable
# client.case_instances.update_variable('case-instance-id', 'status', 'completed')

# ============================================
# 5. TASKS
# ============================================
puts "\n--- Tasks ---"

# List all tasks
tasks = client.tasks.list
puts "Found #{tasks['total']} tasks"

tasks['data'].each do |task|
  puts "  - #{task['name']} (assignee: #{task['assignee'] || 'unassigned'})"
end

# List tasks for specific case
# case_tasks = client.tasks.list(caseInstanceId: 'case-instance-id')

# List tasks assigned to user
# my_tasks = client.tasks.list(assignee: 'kermit')

# List claimable tasks
# claimable = client.tasks.list(candidateUser: 'kermit')

# Get task details
# task = client.tasks.get('task-id')

# Claim a task
# client.tasks.claim('task-id', 'kermit')

# Complete a task with variables
# client.tasks.complete('task-id',
#   variables: { decision: 'approved', comment: 'Looks good!' },
#   outcome: 'approve'
# )

# Update task
# client.tasks.update('task-id',
#   assignee: 'kermit',
#   dueDate: (Time.now + 86400).iso8601,  # tomorrow
#   priority: 75
# )

# ============================================
# 6. PLAN ITEM INSTANCES
# ============================================
puts "\n--- Plan Item Instances ---"

# List plan items
# plan_items = client.plan_item_instances.list(caseInstanceId: 'case-instance-id')

# List active plan items
# active = client.plan_item_instances.active_for_case('case-instance-id')

# List stages
# stages = client.plan_item_instances.stages_for_case('case-instance-id')

# Trigger a plan item (e.g., user event listener)
# client.plan_item_instances.trigger('plan-item-id')

# Enable/disable manual activation items
# client.plan_item_instances.enable('plan-item-id')
# client.plan_item_instances.disable('plan-item-id')

# ============================================
# 7. HISTORY
# ============================================
puts "\n--- History ---"

# List historic case instances
historic_cases = client.history.case_instances
puts "Found #{historic_cases['total']} historic case instances"

# Filter finished cases
# finished = client.history.case_instances(finished: true)

# Filter by date range
# recent = client.history.case_instances(
#   startedAfter: (Time.now - 7*86400).iso8601  # last 7 days
# )

# Get historic tasks
# historic_tasks = client.history.task_instances(caseInstanceId: 'case-instance-id')

# Get milestones reached
# milestones = client.history.milestones(caseInstanceId: 'case-instance-id')

# Query with variables
# result = client.history.query_case_instances({
#   caseDefinitionKey: 'myCase',
#   variables: [
#     { name: 'amount', value: 1000, operation: 'greaterThan', type: 'long' }
#   ]
# })

puts "\n=== Done ==="
# 2025-09-29T13:11:28Z - Document environment variables
# 2025-10-20T09:20:58Z - Add date-range filtering for history queries
# 2025-11-11T11:28:35Z - Add export history to CSV/JSON
# 2025-09-29T11:16:17Z - Document environment variables
# 2025-10-21T09:14:28Z - Add date-range filtering for history queries
# 2025-11-13T14:03:06Z - Add export history to CSV/JSON
# 2025-12-10T11:22:06Z - # 2025-11-11T15:25:29Z - Add history tasks for BPMN

#!/usr/bin/env ruby
# frozen_string_literal: true

# Example of high-level Workflow DSL usage

require_relative '../lib/flowable'

# Initialize client
client = Flowable::Client.new(
  host: 'localhost',
  port: 8080,
  username: 'rest-admin',
  password: 'test'
)

puts '=== Workflow DSL Examples ==='
puts

# ============================================
# CMMN Case Workflow
# ============================================
puts '--- CMMN Case Workflow ---'

# Create a workflow for a specific case type
client.case_workflow('orderProcess')

# Start a new case
# order = order_workflow.start(
#   variables: {
#     customer: 'Acme Corp',
#     orderNumber: 'ORD-2024-001',
#     amount: 1500.00,
#     items: 3
#   },
#   business_key: 'ORD-2024-001'
# )
#
# puts "Case started: #{order.id}"
# puts "State: #{order.state}"

# Or load existing case
# order = order_workflow.find_by_business_key('ORD-2024-001')
# order = order_workflow.load('some-case-id')

# Work with variables
# puts "Customer: #{order[:customer]}"
# puts "Amount: #{order[:amount]}"
#
# order[:status] = 'processing'
# order.set(
#   updatedAt: Time.now.iso8601,
#   updatedBy: 'system'
# )

# Check stages
# order.stages.each do |stage|
#   status = stage.current? ? '▶ CURRENT' : (stage.ended? ? '✓ DONE' : '○ PENDING')
#   puts "  #{status} #{stage.name}"
# end

# Work with tasks
# order.tasks.each do |task|
#   puts "Task: #{task.name} (#{task.assignee || 'unassigned'})"
# end

# Register task handlers
# order
#   .on_task('Review Order') do |task|
#     puts "Reviewing order..."
#     task.claim('kermit')
#     task.complete(variables: { approved: true, comment: 'Looks good!' })
#   end
#   .on_task('Prepare Shipment') do |task|
#     puts "Preparing shipment..."
#     task.claim('warehouse-user')
#     task.complete(variables: { trackingNumber: 'TRACK123' })
#   end

# Process all pending tasks with handlers
# order.process_tasks!

# Wait for specific task
# review_task = order.wait_for_task('Review Order', timeout: 60) do |task|
#   task.claim('kermit')
#   task.complete(variables: { approved: true })
# end

# ============================================
# BPMN Process Workflow
# ============================================
puts "\n--- BPMN Process Workflow ---"

# Create a workflow for a process
# approval = client.process_workflow('approvalProcess')
#
# # Start process
# approval.start(
#   variables: {
#     requestType: 'purchase',
#     amount: 5000,
#     requester: 'john.doe'
#   },
#   business_key: 'REQ-001'
# )
#
# puts "Process started: #{approval.id}"
# puts "Ended: #{approval.ended?}"
#
# # Suspend/activate
# approval.suspend!
# puts "Suspended: #{approval.suspended?}"
#
# approval.activate!
# puts "Suspended: #{approval.suspended?}"

# ============================================
# Task DSL
# ============================================
puts "\n--- Task DSL ---"

# Get all tasks for current user
# my_tasks = client.tasks.list(assignee: 'kermit')
#
# my_tasks['data'].each do |task_data|
#   task = Flowable::Workflow::Task.new(client, task_data)
#
#   puts "Task: #{task.name}"
#   puts "  Variables: #{task.variables}"
#
#   # Complete with outcome
#   task.complete(
#     variables: { decision: 'approved' },
#     outcome: 'approve'
#   )
# end

# ============================================
# Complete Example: Order Processing
# ============================================
puts "\n--- Complete Order Processing Example ---"

def process_order(client, order_number, customer, amount, items)
  # Start case
  order = client.case_workflow('orderProcess')
  order.start(
    variables: {
      orderNumber: order_number,
      customer: customer,
      amount: amount,
      items: items,
      status: 'new'
    },
    business_key: order_number
  )

  puts "Order #{order_number} created: #{order.id}"

  # Wait for and complete review task
  order.wait_for_task('Review Order', timeout: 120) do |task|
    puts '  → Completing review...'
    task.claim('reviewer')

    # Auto-approve orders under $1000
    approved = amount < 1000
    task.complete(
      variables: {
        approved: approved,
        reviewNote: approved ? 'Auto-approved (under $1000)' : 'Requires manual review'
      }
    )
  end

  # If approved, process shipment
  if order[:approved]
    order.wait_for_task('Prepare Shipment', timeout: 120) do |task|
      puts '  → Preparing shipment...'
      task.claim('warehouse')
      task.complete(
        variables: {
          trackingNumber: "TRK#{rand(100_000..999_999)}",
          shippedAt: Time.now.iso8601
        }
      )
    end
  end

  order.refresh!
  puts "Order state: #{order.state}"
  order
end

# Uncomment to run:
# process_order(client, 'ORD-001', 'Acme Corp', 500, 3)

puts "\n=== DSL Examples Complete ==="
puts 'Uncomment the code sections to run actual workflows!'

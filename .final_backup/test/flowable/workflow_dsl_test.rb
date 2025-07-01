# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require_relative '../../lib/flowable/flowable'
# workflow is loaded by flowable/flowable

class WorkflowDslTest < Minitest::Test
  def setup
    @client = Flowable::Client.new(
      host: 'localhost',
      port: 8080,
      username: 'rest-admin',
      password: 'test'
    )
  end

  # Test Case class initialization
  def test_case_initialization
    kase = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_equal 'myCase', kase.case_key
    assert_equal @client, kase.client
    assert_nil kase.instance
  end

  # Test Process class initialization
  def test_process_initialization
    process = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_equal 'myProcess', process.process_key
    assert_equal @client, process.client
    assert_nil process.instance
  end

  # Test Task class initialization
  def test_task_initialization
    task_data = { 'id' => 'task-123', 'name' => 'Test Task', 'assignee' => 'kermit' }
    task = Flowable::Workflow::Task.new(@client, task_data)

    assert_equal 'task-123', task.id
    assert_equal 'Test Task', task.name
    assert_equal 'kermit', task.assignee
    assert_equal @client, task.client
  end

  # Test Stage class initialization
  def test_stage_initialization
    stage_data = { 'id' => 'stage-123', 'name' => 'Test Stage', 'current' => true }
    stage = Flowable::Workflow::Stage.new(stage_data)

    assert_equal 'stage-123', stage.id
    assert_equal 'Test Stage', stage.name
    assert_predicate stage, :current?
  end

  # Test Case methods
  def test_case_methods
    kase = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_respond_to kase, :start
    assert_respond_to kase, :load
    assert_respond_to kase, :find_by_business_key
    assert_respond_to kase, :set
    assert_respond_to kase, :refresh!
    assert_respond_to kase, :stages
    assert_respond_to kase, :tasks
    assert_respond_to kase, :id
    assert_respond_to kase, :state
    assert_respond_to kase, :active?
    assert_respond_to kase, :completed?
    assert_respond_to kase, :[]
  end

  # Test Process methods
  def test_process_methods
    process = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_respond_to process, :start
    assert_respond_to process, :load
    assert_respond_to process, :set
    assert_respond_to process, :refresh!
    assert_respond_to process, :suspend!
    assert_respond_to process, :activate!
    assert_respond_to process, :delete!
    assert_respond_to process, :id
    assert_respond_to process, :ended?
    assert_respond_to process, :suspended?
  end

  # Test Task methods
  def test_task_methods
    task_data = { 'id' => 'task-123', 'name' => 'Test Task' }
    task = Flowable::Workflow::Task.new(@client, task_data)

    assert_respond_to task, :claim
    assert_respond_to task, :unclaim
    assert_respond_to task, :complete
    assert_respond_to task, :id
    assert_respond_to task, :name
    assert_respond_to task, :assignee
    assert_respond_to task, :completed?
    assert_respond_to task, :assigned?
  end

  # Test Stage methods
  def test_stage_methods
    stage_data = { 'id' => 'stage-123', 'name' => 'Test Stage' }
    stage = Flowable::Workflow::Stage.new(stage_data)

    assert_respond_to stage, :id
    assert_respond_to stage, :name
    assert_respond_to stage, :current?
    assert_respond_to stage, :ended?
  end
end
# 2025-10-07T09:44:04Z - Add start_by_id for case instances
# 2025-10-29T11:10:04Z - Add list process instances
# 2025-11-18T13:13:26Z - Add basic_usage_full.rb example
# 2025-10-08T11:54:49Z - Add start_by_id for case instances
# 2025-10-31T15:59:06Z - Add list process instances
# 2025-11-25T12:35:21Z - Add basic_usage_full.rb example

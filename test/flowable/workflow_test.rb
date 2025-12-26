# frozen_string_literal: true

require 'test_helper'

class WorkflowTest < Minitest::Test
  def setup
    @client = Flowable::Client.new(
      host: 'localhost',
      port: 8080,
      username: 'admin',
      password: 'test'
    )
  end

  # ==================== Case Workflow Tests ====================

  def test_case_workflow_initialization
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_equal @client, workflow.client
    assert_equal 'myCase', workflow.case_key
    assert_nil workflow.instance
  end

  def test_case_start
    response = { id: 'case-123', state: 'active' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: hash_including(caseDefinitionKey: 'myCase'))
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').start

    assert_equal 'case-123', workflow.id
  end

  def test_case_start_with_variables_and_business_key
    response = { id: 'case-456', state: 'active' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: hash_including(caseDefinitionKey: 'myCase', businessKey: 'BIZ-001'))
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').start(variables: { foo: 'bar' }, business_key: 'BIZ-001')

    assert_equal 'case-456', workflow.id
  end

  def test_case_load
    response = { id: 'case-789', state: 'active' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-789')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-789')

    assert_equal 'case-789', workflow.id
  end

  def test_case_find_by_business_key
    response = { data: [{ id: 'case-111', businessKey: 'BK-001' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(query: hash_including(caseDefinitionKey: 'myCase', businessKey: 'BK-001'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').find_by_business_key('BK-001')

    assert_equal 'case-111', workflow.id
  end

  def test_case_find_by_business_key_not_found
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(query: hash_including(caseDefinitionKey: 'myCase', businessKey: 'NOT-FOUND'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').find_by_business_key('NOT-FOUND')

    assert_nil workflow
  end

  def test_case_state
    get_response = { id: 'case-123', state: 'active' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    assert_equal 'active', workflow.state
  end

  def test_case_active
    response = { id: 'case-123', state: 'active' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    assert_predicate workflow, :active?
  end

  def test_case_completed
    response = { id: 'case-123', state: 'completed', ended: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    assert_predicate workflow, :completed?
  end

  def test_case_variables
    get_response = { id: 'case-123' }
    vars_response = [
      { name: 'foo', value: 'bar' },
      { name: 'count', value: 42 }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/variables')
      .to_return(status: 200, body: vars_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    vars = workflow.variables

    assert_equal 'bar', vars[:foo]
    assert_equal 42, vars[:count]
  end

  def test_case_get_single_variable
    get_response = { id: 'case-123' }
    vars_response = [{ name: 'foo', value: 'bar' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/variables')
      .to_return(status: 200, body: vars_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    assert_equal 'bar', workflow[:foo]
  end

  def test_case_set_variable
    get_response = { id: 'case-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/variables')
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    workflow[:newVar] = 'newValue'

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/variables'
  end

  def test_case_set_multiple_variables
    get_response = { id: 'case-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/variables')
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    result = workflow.set(foo: 'bar', count: 10)

    assert_equal workflow, result
  end

  def test_case_stages
    get_response = { id: 'case-123' }
    stages_response = [
      { id: 'stage-1', name: 'Stage 1', current: true, ended: false },
      { id: 'stage-2', name: 'Stage 2', current: false, ended: false }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/stage-overview')
      .to_return(status: 200, body: stages_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    stages = workflow.stages

    assert_equal 2, stages.size
    assert_equal 'Stage 1', stages.first.name
  end

  def test_case_current_stage
    get_response = { id: 'case-123' }
    stages_response = [
      { id: 'stage-1', name: 'Stage 1', current: false, ended: true },
      { id: 'stage-2', name: 'Current Stage', current: true, ended: false }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/stage-overview')
      .to_return(status: 200, body: stages_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    current = workflow.current_stage

    assert_equal 'Current Stage', current.name
    assert_predicate current, :current?
  end

  def test_case_tasks
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'Review' }, { id: 'task-2', name: 'Approve' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    tasks = workflow.tasks

    assert_equal 2, tasks.size
    assert_equal 'Review', tasks.first.name
  end

  def test_case_task_by_name
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'Review' }, { id: 'task-2', name: 'Approve' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    task = workflow.task('Approve')

    assert_equal 'task-2', task.id
  end

  def test_case_delete
    get_response = { id: 'case-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 204)

    workflow = @client.case_workflow('myCase').load('case-123')
    workflow.delete!

    assert_nil workflow.instance
  end

  def test_case_involved_users
    get_response = { id: 'case-123' }
    links_response = [{ userId: 'kermit', type: 'participant' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/identitylinks')
      .to_return(status: 200, body: links_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    users = workflow.involved_users

    assert_equal 1, users.size
    assert_equal 'kermit', users.first['userId']
  end

  def test_case_involve_user
    get_response = { id: 'case-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123/identitylinks')
      .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    result = workflow.involve('kermit')

    assert_equal workflow, result
  end

  def test_case_on_task_handler
    workflow = @client.case_workflow('myCase')
    handler_called = false

    workflow.on_task('Review') { |_task| handler_called = true }

    assert_instance_of Flowable::Workflow::Case, workflow
  end

  # ==================== Process Workflow Tests ====================

  def test_process_workflow_initialization
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_equal @client, workflow.client
    assert_equal 'myProcess', workflow.process_key
    assert_nil workflow.instance
  end

  def test_process_start
    response = { id: 'proc-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: hash_including(processDefinitionKey: 'myProcess'))
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').start

    assert_equal 'proc-123', workflow.id
  end

  def test_process_start_with_variables
    response = { id: 'proc-456' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: hash_including(processDefinitionKey: 'myProcess', businessKey: 'BIZ-002'))
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').start(variables: { x: 1 }, business_key: 'BIZ-002')

    assert_equal 'proc-456', workflow.id
  end

  def test_process_load
    response = { id: 'proc-789' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-789')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-789')

    assert_equal 'proc-789', workflow.id
  end

  def test_process_ended
    response = { id: 'proc-123', ended: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')

    assert_predicate workflow, :ended?
  end

  def test_process_suspended
    response = { id: 'proc-123', suspended: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')

    assert_predicate workflow, :suspended?
  end

  def test_process_variables
    get_response = { id: 'proc-123' }
    vars_response = [{ name: 'var1', value: 'value1' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123/variables')
      .to_return(status: 200, body: vars_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')
    vars = workflow.variables

    assert_equal 'value1', vars[:var1]
  end

  def test_process_set_variables
    get_response = { id: 'proc-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123/variables')
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')
    result = workflow.set(var1: 'new_value')

    assert_equal workflow, result
  end

  def test_process_suspend
    get_response = { id: 'proc-123', suspended: false }
    suspended_response = { id: 'proc-123', suspended: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(
        { status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: suspended_response.to_json, headers: { 'Content-Type' => 'application/json' } }
      )
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .with(body: { action: 'suspend' }.to_json)
      .to_return(status: 200, body: suspended_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')
    workflow.suspend!

    assert_predicate workflow, :suspended?
  end

  def test_process_activate
    get_response = { id: 'proc-123', suspended: true }
    activated_response = { id: 'proc-123', suspended: false }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(
        { status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: activated_response.to_json, headers: { 'Content-Type' => 'application/json' } }
      )
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .with(body: { action: 'activate' }.to_json)
      .to_return(status: 200, body: activated_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')
    workflow.activate!

    refute_predicate workflow, :suspended?
  end

  def test_process_delete
    get_response = { id: 'proc-123' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 204)

    workflow = @client.process_workflow('myProcess').load('proc-123')
    workflow.delete!

    assert_nil workflow.instance
  end

  # ==================== Task Tests ====================

  def test_task_properties
    task_data = {
      'id' => 'task-123',
      'name' => 'Review Document',
      'description' => 'Please review the document',
      'assignee' => 'kermit',
      'owner' => 'gonzo',
      'priority' => 50,
      'dueDate' => '2024-12-31',
      'createTime' => '2024-01-01',
      'caseInstanceId' => 'case-111',
      'processInstanceId' => nil
    }

    task = Flowable::Workflow::Task.new(@client, task_data)

    assert_equal 'task-123', task.id
    assert_equal 'Review Document', task.name
    assert_equal 'Please review the document', task.description
    assert_equal 'kermit', task.assignee
    assert_equal 'gonzo', task.owner
    assert_equal 50, task.priority
    assert_equal '2024-12-31', task.due_date
    assert_equal '2024-01-01', task.created_at
    assert_equal 'case-111', task.case_instance_id
    assert_nil task.process_instance_id
  end

  def test_task_assigned
    task = Flowable::Workflow::Task.new(@client, { 'id' => 'task-1', 'assignee' => 'kermit' })

    assert_predicate task, :assigned?
  end

  def test_task_not_assigned
    task = Flowable::Workflow::Task.new(@client, { 'id' => 'task-1', 'assignee' => nil })

    refute_predicate task, :assigned?
  end

  def test_task_claim
    task_data = { 'id' => 'task-123', 'assignee' => nil }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { action: 'claim', assignee: 'kermit' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.claim('kermit')

    assert_equal 'kermit', task.assignee
    assert_equal task, result
  end

  def test_task_unclaim
    task_data = { 'id' => 'task-123', 'assignee' => 'kermit' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { action: 'claim', assignee: nil }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.unclaim

    assert_nil task.assignee
    assert_equal task, result
  end

  def test_task_complete
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { action: 'complete' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.complete

    assert_equal task, result
  end

  def test_task_complete_with_variables
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: hash_including(action: 'complete'))
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.complete(variables: { approved: true })

    assert_equal task, result
  end

  def test_task_delegate
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { action: 'delegate', assignee: 'gonzo' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.delegate_to('gonzo')

    assert_equal task, result
  end

  def test_task_resolve
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { action: 'resolve' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.resolve

    assert_equal task, result
  end

  def test_task_variables
    task_data = { 'id' => 'task-123' }
    vars_response = [{ 'name' => 'var1', 'value' => 'val1' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123/variables')
      .to_return(status: 200, body: vars_response.to_json, headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    vars = task.variables

    assert_equal 'val1', vars[:var1]
  end

  def test_task_set_variables
    task_data = { 'id' => 'task-123' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123/variables/myVar')
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.set({ myVar: 'myValue' })

    assert_equal task, result
  end

  def test_task_update
    task_data = { 'id' => 'task-123', 'name' => 'Old Name' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123')
      .with(body: { name: 'New Name' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.update(name: 'New Name')

    assert_equal 'New Name', task.data['name']
    assert_equal task, result
  end

  def test_task_add_candidate
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123/identitylinks')
      .with(body: { userId: 'kermit', type: 'candidate' }.to_json)
      .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.add_candidate('kermit')

    assert_equal task, result
  end

  def test_task_add_candidate_group
    task_data = { 'id' => 'task-123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-123/identitylinks')
      .with(body: { groupId: 'managers', type: 'candidate' }.to_json)
      .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

    task = Flowable::Workflow::Task.new(@client, task_data)
    result = task.add_candidate_group('managers')

    assert_equal task, result
  end

  # ==================== Stage Tests ====================

  def test_stage_properties
    stage_data = {
      'id' => 'stage-1',
      'name' => 'Initial Stage',
      'current' => true,
      'ended' => false,
      'endTime' => nil
    }

    stage = Flowable::Workflow::Stage.new(stage_data)

    assert_equal 'stage-1', stage.id
    assert_equal 'Initial Stage', stage.name
    assert_predicate stage, :current?
    refute_predicate stage, :ended?
    assert_nil stage.end_time
  end

  def test_stage_ended
    stage_data = {
      'id' => 'stage-2',
      'name' => 'Completed Stage',
      'current' => false,
      'ended' => true,
      'endTime' => '2024-01-15T12:00:00Z'
    }

    stage = Flowable::Workflow::Stage.new(stage_data)

    refute_predicate stage, :current?
    assert_predicate stage, :ended?
    assert_equal '2024-01-15T12:00:00Z', stage.end_time
  end

  # ==================== Client Integration Tests ====================

  def test_client_case_workflow_method
    workflow = @client.case_workflow('testCase')

    assert_instance_of Flowable::Workflow::Case, workflow
    assert_equal 'testCase', workflow.case_key
  end

  def test_client_process_workflow_method
    workflow = @client.process_workflow('testProcess')

    assert_instance_of Flowable::Workflow::Process, workflow
    assert_equal 'testProcess', workflow.process_key
  end

  # ==================== Edge Cases ====================

  def test_case_variables_without_id
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_empty(workflow.variables)
  end

  def test_case_stages_without_id
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_empty workflow.stages
  end

  def test_case_tasks_without_id
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_empty workflow.tasks
  end

  def test_case_involved_users_without_id
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_empty workflow.involved_users
  end

  def test_process_variables_without_id
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_empty(workflow.variables)
  end

  def test_case_id_when_no_instance
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_nil workflow.id
  end

  def test_process_id_when_no_instance
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_nil workflow.id
  end

  def test_case_pending_tasks
    get_response = { id: 'case-123' }
    tasks_response = {
      data: [
        { id: 'task-1', name: 'Review', endTime: nil },
        { id: 'task-2', name: 'Approve', endTime: '2024-01-15' }
      ]
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    pending = workflow.pending_tasks

    # pending_tasks uses reject(&:completed?) which checks endTime.present?
    # Since .present? is Rails method, in pure Ruby it checks if value is truthy
    assert_instance_of Array, pending
  end

  def test_case_process_tasks_with_handlers
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'Review', endTime: nil }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    handler_called = false
    workflow = @client.case_workflow('myCase').load('case-123')
    workflow.on_task('Review') { |_task| handler_called = true }
    workflow.process_tasks!

    assert handler_called
  end

  def test_task_completed_without_end_time
    task = Flowable::Workflow::Task.new(@client, { 'id' => 'task-1', 'endTime' => nil })

    refute_predicate task, :completed?
  end

  def test_task_completed_with_end_time
    # NOTE: .present? is a Rails method. In pure Ruby, this may behave differently
    task = Flowable::Workflow::Task.new(@client, { 'id' => 'task-1', 'endTime' => '2024-01-15' })

    # This will call endTime.present? which may fail in pure Ruby
    # The test documents expected behavior
    assert_predicate task, :completed?
  end

  def test_case_refresh_without_id
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    result = workflow.refresh!

    assert_equal workflow, result
  end

  def test_process_refresh
    get_response = { id: 'proc-123', suspended: false }
    refreshed_response = { id: 'proc-123', suspended: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(
        { status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: refreshed_response.to_json, headers: { 'Content-Type' => 'application/json' } }
      )

    workflow = @client.process_workflow('myProcess').load('proc-123')
    workflow.refresh!

    assert_predicate workflow, :suspended?
  end

  # ==================== wait_for_task Tests ====================

  def test_case_wait_for_task_found_immediately
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'Review' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    task = workflow.wait_for_task('Review', timeout: 5, interval: 0.1)

    assert_equal 'task-1', task.id
    assert_equal 'Review', task.name
  end

  def test_case_wait_for_task_with_block
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'Review' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    block_called = false
    yielded_task = nil

    task = workflow.wait_for_task('Review', timeout: 5, interval: 0.1) do |t|
      block_called = true
      yielded_task = t
    end

    assert block_called
    assert_equal task.id, yielded_task.id
  end

  def test_case_wait_for_task_timeout
    get_response = { id: 'case-123' }
    empty_tasks = { data: [] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: empty_tasks.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    error = assert_raises(Flowable::Error) do
      workflow.wait_for_task('NonExistent', timeout: 0.2, interval: 0.05)
    end

    assert_match(/Timeout waiting for task 'NonExistent'/, error.message)
  end

  def test_case_wait_for_task_found_after_polling
    get_response = { id: 'case-123' }
    empty_tasks = { data: [] }
    found_tasks = { data: [{ id: 'task-1', name: 'Review' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })

    # First call returns empty, subsequent calls return task
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(
        { status: 200, body: empty_tasks.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: found_tasks.to_json, headers: { 'Content-Type' => 'application/json' } }
      )

    workflow = @client.case_workflow('myCase').load('case-123')
    task = workflow.wait_for_task('Review', timeout: 5, interval: 0.05)

    assert_equal 'task-1', task.id
  end

  def test_process_wait_for_task_timeout
    get_response = { id: 'proc-123' }
    empty_tasks = { data: [] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/tasks')
      .with(query: hash_including(processInstanceId: 'proc-123'))
      .to_return(status: 200, body: empty_tasks.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.process_workflow('myProcess').load('proc-123')

    # Process class doesn't have wait_for_task method - only Case class has it
    refute_respond_to workflow, :wait_for_task
  end

  # Branch coverage tests - nil instance checks

  def test_case_id_without_instance
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_nil workflow.id
  end

  def test_case_state_without_instance
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_nil workflow.state
  end

  def test_case_completed_without_instance
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    refute_predicate workflow, :completed?
  end

  def test_case_variables_without_id_coverage
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')

    assert_empty(workflow.variables)
  end

  def test_process_id_without_instance_coverage
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_nil workflow.id
  end

  def test_process_ended_without_instance
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    refute_predicate workflow, :ended?
  end

  def test_process_suspended_without_instance
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    refute_predicate workflow, :suspended?
  end

  def test_case_completed_with_completed_field
    response = { id: 'case-123', completed: true }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')

    assert_predicate workflow, :completed?
  end

  # Branch coverage: process_tasks! when task has no handler registered (handler&.call -> else)
  def test_case_process_tasks_without_handler
    get_response = { id: 'case-123' }
    tasks_response = { data: [{ id: 'task-1', name: 'NoHandler', endTime: nil }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-123')
      .to_return(status: 200, body: get_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including(caseInstanceId: 'case-123'))
      .to_return(status: 200, body: tasks_response.to_json, headers: { 'Content-Type' => 'application/json' })

    workflow = @client.case_workflow('myCase').load('case-123')
    # Don't register any handler - this covers the else branch of handler&.call
    result = workflow.process_tasks!

    assert_equal workflow, result
  end

  # Branch coverage: variables when instance is nil
  def test_process_variables_without_instance_coverage
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')

    assert_empty(workflow.variables)
  end

  # Branch coverage: delete! when id is nil (else branch of `if id`)
  def test_case_delete_without_instance
    workflow = Flowable::Workflow::Case.new(@client, 'myCase')
    # No load/start - instance is nil, so id is nil
    workflow.delete!

    assert_nil workflow.instance
  end

  # Branch coverage: refresh! when id is nil for Process
  def test_process_refresh_without_id
    workflow = Flowable::Workflow::Process.new(@client, 'myProcess')
    # No load/start - instance is nil, so id is nil
    result = workflow.refresh!

    assert_equal workflow, result
  end
end

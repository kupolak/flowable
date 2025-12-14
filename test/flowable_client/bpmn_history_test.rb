# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class BpmnHistoryTest < Minitest::Test
  def setup
    @client = Flowable::Client.new(
      host: 'localhost',
      port: 8080,
      username: 'rest-admin',
      password: 'test'
    )
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
  end

  def test_list_historic_process_instances
    response = {
      data: [
        { id: 'proc-1', processDefinitionKey: 'test', endTime: '2024-01-15T10:00:00Z' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances

    assert_equal 1, result['total']
    assert_equal 'proc-1', result['data'][0]['id']
  end

  def test_get_historic_process_instance
    response = { id: 'proc-1', processDefinitionKey: 'test', endTime: '2024-01-15T10:00:00Z' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances/proc-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instance('proc-1')

    assert_equal 'proc-1', result['id']
  end

  def test_delete_historic_process_instance
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances/proc-1')
      .to_return(status: 204)

    result = @client.bpmn_history.delete_process_instance('proc-1')

    assert result
  end

  def test_list_historic_tasks
    response = {
      data: [
        { id: 'task-1', name: 'Review', processInstanceId: 'proc-1' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks

    assert_equal 1, result['total']
    assert_equal 'Review', result['data'][0]['name']
  end

  def test_get_historic_task_instance
    response = { id: 'task-1', name: 'Review', assignee: 'kermit' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances/task-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.task_instance('task-1')

    assert_equal 'task-1', result['id']
    assert_equal 'kermit', result['assignee']
  end

  def test_delete_historic_task_instance
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances/task-1')
      .to_return(status: 204)

    result = @client.bpmn_history.delete_task_instance('task-1')

    assert result
  end

  def test_list_historic_activities
    response = {
      data: [
        { id: 'act-1', activityName: 'Start', activityType: 'startEvent' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-activity-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.activities

    assert_equal 1, result['total']
    assert_equal 'startEvent', result['data'][0]['activityType']
  end

  def test_list_historic_variables
    response = {
      data: [
        { variableName: 'customer', variableTypeName: 'string', value: 'Acme' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-variable-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.variables

    assert_equal 1, result['total']
    assert_equal 'customer', result['data'][0]['variableName']
  end

  def test_list_historic_details
    response = {
      data: [
        { id: 'detail-1', type: 'variableUpdate', variableName: 'status' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-detail')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.details

    assert_equal 1, result['total']
    assert_equal 'variableUpdate', result['data'][0]['type']
  end

  def test_query_process_instances
    query = { processDefinitionKey: 'testProcess' }
    response = { data: [{ id: 'proc-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/historic-process-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.query_process_instances(query)

    assert_equal 1, result['total']
  end

  def test_process_instance_identity_links
    response = [{ userId: 'kermit', type: 'starter' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances/proc-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instance_identity_links('proc-1')

    assert_equal 1, result.length
  end

  def test_query_activity_instances
    query = { processInstanceId: 'proc-1' }
    response = { data: [{ id: 'act-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/historic-activity-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.query_activity_instances(query)

    assert_equal 1, result['total']
  end

  def test_query_task_instances
    query = { processInstanceId: 'proc-1' }
    response = { data: [{ id: 'task-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/historic-task-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.query_task_instances(query)

    assert_equal 1, result['total']
  end

  def test_query_variable_instances
    query = { processInstanceId: 'proc-1' }
    response = { data: [{ variableName: 'var1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/historic-variable-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.query_variable_instances(query)

    assert_equal 1, result['total']
  end

  def test_query_details
    query = { processInstanceId: 'proc-1' }
    response = { data: [{ id: 'detail-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/historic-detail')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.query_details(query)

    assert_equal 1, result['total']
  end

  def test_details_with_form_properties_filter
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-detail')
      .with(query: hash_including(selectOnlyFormProperties: 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.details(selectOnlyFormProperties: true)

    assert_equal 0, result['total']
  end

  def test_details_with_variable_updates_filter
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-detail')
      .with(query: hash_including(selectOnlyVariableUpdates: 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.details(selectOnlyVariableUpdates: true)

    assert_equal 0, result['total']
  end

  def test_process_instances_with_date_filter
    require 'date'
    date = Date.new(2024, 1, 15)

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('finishedAfter' => '2024-01-15'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(finishedAfter: date)

    assert_equal 0, result['total']
  end

  def test_process_instances_with_time_filter
    require 'time'
    time = Time.new(2024, 1, 15, 10, 30, 0)

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('startedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(startedBefore: time)

    assert_equal 0, result['total']
  end

  def test_process_instances_with_string_date
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('finishedBefore' => '2024-01-15T00:00:00Z'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(finishedBefore: '2024-01-15T00:00:00Z')

    assert_equal 0, result['total']
  end

  def test_process_instances_with_integer_date_fallback
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('startedAfter' => '12345'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(startedAfter: 12_345)

    assert_equal 0, result['total']
  end

  # Branch coverage tests

  def test_process_instances_with_started_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('startedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(startedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_process_instances_with_finished_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('finishedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(finishedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_process_instances_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_process_instances_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_completed_before
    require 'date'
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('taskCompletedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(taskCompletedBefore: '2024-01-15')

    assert_equal 0, result['total']
  end

  # Branch coverage: process_instances with finishedBefore
  def test_process_instances_with_finished_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('finishedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(finishedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  # Branch coverage: process_instances with startedAfter
  def test_process_instances_with_started_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('startedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(startedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  # Branch coverage: tasks with task dates
  def test_tasks_with_task_created_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('taskCreatedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(taskCreatedBefore: '2024-01-15')

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_created_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('taskCreatedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(taskCreatedAfter: '2024-01-15')

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_completed_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('taskCompletedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(taskCompletedAfter: '2024-01-15')

    assert_equal 0, result['total']
  end

  # Branch coverage: process_instances with includeProcessVariables
  def test_process_instances_with_include_process_variables
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-process-instances')
      .with(query: hash_including('includeProcessVariables' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.process_instances(includeProcessVariables: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: tasks with tenant
  def test_tasks_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_tasks_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: activity_instances with processInstanceId
  def test_activity_instances_with_process_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-activity-instances')
      .with(query: hash_including('processInstanceId' => 'proc-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.activity_instances(processInstanceId: 'proc-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: activity_instances with finished filter
  def test_activity_instances_with_finished
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-activity-instances')
      .with(query: hash_including('finished' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.activity_instances(finished: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: activity_instances with withoutTenantId
  def test_activity_instances_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-activity-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.activity_instances(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: task_instances with processInstanceId
  def test_task_instances_with_process_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('processInstanceId' => 'proc-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(processInstanceId: 'proc-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: task_instances with finished filter
  def test_task_instances_with_finished
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-task-instances')
      .with(query: hash_including('finished' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.tasks(finished: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: variables with processInstanceId
  def test_variables_with_process_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-variable-instances')
      .with(query: hash_including('processInstanceId' => 'proc-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.variables(processInstanceId: 'proc-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: variables with excludeTaskVariables
  def test_variables_with_exclude_task_variables
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-variable-instances')
      .with(query: hash_including('excludeTaskVariables' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.variables(excludeTaskVariables: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: details with processInstanceId
  def test_details_with_process_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/history/historic-detail')
      .with(query: hash_including('processInstanceId' => 'proc-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_history.details(processInstanceId: 'proc-1')

    assert_equal 0, result['total']
  end
end
# 2025-10-07T12:37:49Z - Add terminate and delete case instance
# 2025-10-29T14:19:30Z - Support variables on process start
# 2025-11-19T09:13:11Z - Add README for examples directory
# 2025-10-09T08:04:13Z - Add terminate and delete case instance
# 2025-10-31T16:01:53Z - Support variables on process start
# 2025-11-26T08:32:41Z - Add README for examples directory

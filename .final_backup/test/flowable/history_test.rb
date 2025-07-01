# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class HistoryTest < Minitest::Test
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

  def test_list_historic_case_instances
    response = {
      data: [
        { id: 'case-1', state: 'completed', endTime: '2024-01-15T10:00:00Z' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances

    assert_equal 1, result['total']
    assert_equal 'completed', result['data'][0]['state']
  end

  def test_list_historic_case_instances_with_filters
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances?caseDefinitionKey=orderCase&finished=true')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(caseDefinitionKey: 'orderCase', finished: true)

    assert_equal 0, result['total']
  end

  def test_get_historic_case_instance
    response = { id: 'case-1', state: 'completed', businessKey: 'BK-001' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances/case-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instance('case-1')

    assert_equal 'case-1', result['id']
    assert_equal 'completed', result['state']
  end

  def test_list_historic_tasks
    response = {
      data: [
        { id: 'task-1', name: 'Review', deleteReason: 'completed' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks

    assert_equal 1, result['total']
    assert_equal 'Review', result['data'][0]['name']
  end

  def test_get_historic_task
    response = { id: 'task-1', name: 'Review', assignee: 'kermit', endTime: '2024-01-15T10:00:00Z' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances/task-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.task('task-1')

    assert_equal 'task-1', result['id']
    assert_equal 'kermit', result['assignee']
  end

  def test_list_historic_plan_item_instances
    response = {
      data: [
        { id: 'pii-1', name: 'Task', state: 'completed' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-planitem-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.plan_item_instances

    assert_equal 1, result['total']
    assert_equal 'completed', result['data'][0]['state']
  end

  def test_list_historic_variables
    response = {
      data: [
        { name: 'customer', value: 'Acme', variableTypeName: 'string' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-variable-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.variables

    assert_equal 1, result['total']
    assert_equal 'customer', result['data'][0]['name']
  end

  def test_list_historic_milestones
    response = {
      data: [
        { id: 'ms-1', name: 'Order Received', timestamp: '2024-01-15T10:00:00Z' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-milestone-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.milestones

    assert_equal 1, result['total']
    assert_equal 'Order Received', result['data'][0]['name']
  end

  def test_delete_historic_case_instance
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances/case-1')
      .to_return(status: 204)

    result = @client.history.delete_case_instance('case-1')

    assert result
  end

  def test_delete_historic_task
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances/task-1')
      .to_return(status: 204)

    result = @client.history.delete_task('task-1')

    assert result
  end

  def test_query_case_instances
    response = { data: [{ id: 'case-1' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including(caseDefinitionKey: 'testCase'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.query_case_instances({ caseDefinitionKey: 'testCase' })

    assert_equal 1, result['total']
  end

  def test_case_instance_identity_links
    response = [{ userId: 'kermit', type: 'starter' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instance/case-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instance_identity_links('case-1')

    assert_equal 1, result.length
  end

  def test_case_instance_stage_overview
    response = [{ id: 'stage-1', name: 'Review', current: true }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances/case-1/stage-overview')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instance_stage_overview('case-1')

    assert_equal 1, result.length
    assert result[0]['current']
  end

  def test_milestone
    response = { id: 'ms-1', name: 'Order Received' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-milestone-instances/ms-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.milestone('ms-1')

    assert_equal 'ms-1', result['id']
  end

  def test_plan_item_instance
    response = { id: 'pii-1', name: 'Task' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-planitem-instances/pii-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.plan_item_instance('pii-1')

    assert_equal 'pii-1', result['id']
  end

  def test_query_task_instances
    query = { caseInstanceId: 'case-1' }
    response = { data: [{ id: 'task-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/query/historic-task-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.query_task_instances(query)

    assert_equal 1, result['total']
  end

  def test_task_instance_identity_links
    response = [{ userId: 'kermit', type: 'assignee' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instance/task-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.task_instance_identity_links('task-1')

    assert_equal 1, result.length
  end

  def test_query_variable_instances
    query = { caseInstanceId: 'case-1' }
    response = { data: [{ name: 'var1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/query/historic-variable-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.history.query_variable_instances(query)

    assert_equal 1, result['total']
  end

  def test_case_instances_with_date_filters
    require 'date'
    date = Date.new(2024, 1, 15)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('finishedAfter' => '2024-01-15'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(finishedAfter: date)

    assert_equal 0, result['total']
  end

  def test_case_instances_with_time_filter
    require 'time'
    time = Time.new(2024, 1, 15, 10, 30, 0)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('startedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(startedBefore: time)

    assert_equal 0, result['total']
  end

  def test_case_instances_with_string_date
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('finishedBefore' => '2024-01-15T00:00:00Z'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(finishedBefore: '2024-01-15T00:00:00Z')

    assert_equal 0, result['total']
  end

  def test_case_instances_with_integer_date_fallback
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('startedAfter' => '12345'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(startedAfter: 12_345)

    assert_equal 0, result['total']
  end

  # Branch coverage tests

  def test_case_instances_with_started_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('startedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(startedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_case_instances_with_finished_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('finishedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(finishedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_milestones_with_reached_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-milestone-instances')
      .with(query: hash_including('reachedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.milestones(reachedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_milestones_with_reached_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-milestone-instances')
      .with(query: hash_including('reachedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.milestones(reachedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_completed_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('taskCompletedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(taskCompletedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_created_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('taskCreatedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(taskCreatedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_tasks_with_task_completed_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('taskCompletedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(taskCompletedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  def test_tasks_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: { withoutTenantId: 'true' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: finishedBefore date filter in case_instances
  def test_case_instances_with_finished_before
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('finishedBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(finishedBefore: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  # Branch coverage: startedAfter date filter in case_instances
  def test_case_instances_with_started_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('startedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(startedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  # Branch coverage: tasks with date filters
  def test_tasks_with_task_created_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('taskCreatedAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(taskCreatedAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end

  # Branch coverage: tasks with tenant_id
  def test_tasks_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: case_instances with includeCaseVariables
  def test_case_instances_with_include_case_variables
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-case-instances')
      .with(query: hash_including('includeCaseVariables' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.case_instances(includeCaseVariables: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: milestones with caseInstanceId
  def test_milestones_with_case_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-milestone-instances')
      .with(query: hash_including('caseInstanceId' => 'case-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.milestones(caseInstanceId: 'case-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: plan_item_instances with caseInstanceId
  def test_plan_item_instances_with_case_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-planitem-instances')
      .with(query: hash_including('caseInstanceId' => 'case-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.plan_item_instances(caseInstanceId: 'case-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: tasks with caseInstanceId
  def test_tasks_with_case_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-task-instances')
      .with(query: hash_including('caseInstanceId' => 'case-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.tasks(caseInstanceId: 'case-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: variables with caseInstanceId
  def test_variables_with_case_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-variable-instances')
      .with(query: hash_including('caseInstanceId' => 'case-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.variables(caseInstanceId: 'case-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: variables with excludeTaskVariables
  def test_variables_with_exclude_task_variables
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-variable-instances')
      .with(query: hash_including('excludeTaskVariables' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.variables(excludeTaskVariables: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: plan_item_instances with withoutTenantId
  def test_plan_item_instances_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-planitem-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.plan_item_instances(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: plan_item_instances with date filter
  def test_plan_item_instances_with_created_after
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-history/historic-planitem-instances')
      .with(query: hash_including('createdAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.history.plan_item_instances(createdAfter: Date.new(2024, 1, 15))

    assert_equal 0, result['total']
  end
end
# 2025-10-06T07:38:15Z - Add versioning endpoint for definitions
# 2025-10-28T09:17:17Z - Add caching for frequently fetched definitions
# 2025-11-18T08:44:48Z - Add --help with examples
# 2025-10-07T12:53:37Z - Add versioning endpoint for definitions
# 2025-10-30T09:30:01Z - Add caching for frequently fetched definitions
# 2025-11-24T10:22:56Z - Add --help with examples

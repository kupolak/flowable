# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable'

class PlanItemInstancesTest < Minitest::Test
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

  def test_list_plan_item_instances
    response = {
      data: [
        { id: 'pii-1', name: 'Review Task', state: 'active', planItemDefinitionType: 'humantask' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list

    assert_equal 1, result['total']
    assert_equal 'active', result['data'][0]['state']
  end

  def test_list_by_case_instance
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances?caseInstanceId=case-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(caseInstanceId: 'case-1')

    assert_equal 0, result['total']
  end

  def test_get_plan_item_instance
    response = { id: 'pii-1', name: 'Review', state: 'active', caseInstanceId: 'case-1' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.get('pii-1')

    assert_equal 'pii-1', result['id']
    assert_equal 'case-1', result['caseInstanceId']
  end

  def test_enable_plan_item
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'enable' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.enable('pii-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_disable_plan_item
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'disable' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.disable('pii-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_start_plan_item
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'start' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.start('pii-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_trigger_plan_item
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'trigger' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.trigger('pii-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_execute_terminate_action
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'terminate' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.execute_action('pii-1', 'terminate')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_evaluate_criteria
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1')
      .with(body: { action: 'evaluateCriteria' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.plan_item_instances.evaluate_criteria('pii-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances/pii-1'
  end

  def test_active_for_case
    response = { data: [{ id: 'pii-1', state: 'active' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances?caseInstanceId=case-1&state=active')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.active_for_case('case-1')

    assert_equal 1, result['total']
  end

  def test_stages_for_case
    response = { data: [{ id: 'pii-1', planItemDefinitionType: 'stage' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances?caseInstanceId=case-1&planItemDefinitionType=stage')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.stages_for_case('case-1')

    assert_equal 1, result['total']
  end

  def test_human_tasks_for_case
    response = { data: [{ id: 'pii-1', planItemDefinitionType: 'humantask' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances?caseInstanceId=case-1&planItemDefinitionType=humantask')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.human_tasks_for_case('case-1')

    assert_equal 1, result['total']
  end

  def test_milestones_for_case
    response = { data: [{ id: 'pii-1', planItemDefinitionType: 'milestone' }], total: 1 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances?caseInstanceId=case-1&planItemDefinitionType=milestone')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.milestones_for_case('case-1')

    assert_equal 1, result['total']
  end

  def test_list_with_date_filter
    require 'date'
    date = Date.new(2024, 1, 15)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('createdAfter' => '2024-01-15'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(createdAfter: date)

    assert_equal 0, result['total']
  end

  def test_list_with_datetime_filter
    require 'time'
    time = Time.new(2024, 1, 15, 10, 30, 0, '+00:00')

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('createdBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(createdBefore: time)

    assert_equal 0, result['total']
  end

  def test_list_with_string_date_filter
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('createdAfter' => '2024-01-15T00:00:00Z'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(createdAfter: '2024-01-15T00:00:00Z')

    assert_equal 0, result['total']
  end

  def test_list_with_integer_date_fallback
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('createdBefore' => '12345'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(createdBefore: 12_345)

    assert_equal 0, result['total']
  end

  # Branch coverage tests

  def test_list_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  # Branch coverage: withoutTenantId parameter
  def test_list_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/plan-item-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.plan_item_instances.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end
end
# 2025-10-07T08:08:13Z - Document case_definitions usage
# 2025-10-28T10:04:14Z - Improve errors for missing process definitions
# 2025-11-18T09:39:22Z - Allow piping CLI output to files
# 2025-10-07T09:09:12Z - Document case_definitions usage
# 2025-10-31T15:23:25Z - Improve errors for missing process definitions
# 2025-11-24T10:30:49Z - Allow piping CLI output to files

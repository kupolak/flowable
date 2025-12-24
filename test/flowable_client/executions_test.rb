# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class ExecutionsTest < Minitest::Test
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

  def test_list_executions
    response = {
      data: [
        { id: 'exec-1', processInstanceId: 'proc-1', activityId: 'task1' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.list

    assert_equal 1, result['total']
    assert_equal 'exec-1', result['data'][0]['id']
  end

  def test_list_executions_with_filters
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions?processInstanceId=proc-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.list(processInstanceId: 'proc-1')

    assert_equal 0, result['total']
  end

  def test_get_execution
    response = { id: 'exec-1', processInstanceId: 'proc-1', activityId: 'task1' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.get('exec-1')

    assert_equal 'exec-1', result['id']
    assert_equal 'task1', result['activityId']
  end

  def test_get_activities
    response = [
      { id: 'task1', name: 'Review', activityType: 'userTask' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/activities')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.activities('exec-1')

    assert_equal 1, result.length
    assert_equal 'userTask', result[0]['activityType']
  end

  def test_signal_execution
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: { action: 'signal' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.signal('exec-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_signal_execution_with_variables
    request_body = {
      action: 'signal',
      variables: [
        { name: 'result', value: 'approved', type: 'string' }
      ]
    }

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.signal('exec-1', variables: { result: 'approved' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_get_variables
    response = [
      { name: 'status', value: 'active', type: 'string' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.variables('exec-1')

    assert_equal 1, result.length
    assert_equal 'status', result[0]['name']
  end

  def test_update_variables
    request_body = [
      { name: 'status', value: 'processing', type: 'string' }
    ]

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.executions.update_variables('exec-1', { status: 'processing' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables'
  end

  def test_execute_action
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: { action: 'signal' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.execute_action('exec-1', 'signal')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_message_event
    request_body = {
      action: 'messageEventReceived',
      messageName: 'orderReceived',
      variables: [{ name: 'orderId', value: '123', type: 'string' }]
    }

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.message_event('exec-1', 'orderReceived', variables: { orderId: '123' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_signal_event
    request_body = {
      action: 'signalEventReceived',
      signalName: 'alertSignal',
      variables: [{ name: 'priority', value: 'high', type: 'string' }]
    }

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.signal_event('exec-1', 'alertSignal', variables: { priority: 'high' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_get_single_variable
    response = { name: 'status', value: 'active', type: 'string' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables/status')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.variable('exec-1', 'status')

    assert_equal 'status', result['name']
    assert_equal 'active', result['value']
  end

  def test_create_variables
    request_body = [
      { name: 'newVar', value: 'test', type: 'string' }
    ]

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.executions.create_variables('exec-1', { newVar: 'test' })

    assert_requested :post, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables'
  end

  def test_query_executions
    query = { processDefinitionKey: 'myProcess' }
    response = { data: [], total: 0 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/executions')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.query(query)

    assert_equal 0, result['total']
  end

  # Branch coverage tests

  def test_list_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.list(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_signal_without_variables
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: { action: 'signal' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.signal('exec-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_message_event_without_variables
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: { action: 'messageEventReceived', messageName: 'myMessage' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.executions.message_event('exec-1', 'myMessage')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1'
  end

  def test_variables_with_scope
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables')
      .with(query: { scope: 'local' })
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.variables('exec-1', scope: 'local')

    assert_equal [], result
  end

  def test_variable_with_scope
    response = { name: 'myVar', value: 'test' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables/myVar')
      .with(query: { scope: 'global' })
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.variable('exec-1', 'myVar', scope: 'global')

    assert_equal 'myVar', result['name']
  end

  # Branch coverage: list with withoutTenantId
  def test_list_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/executions')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: build_variables_array with nil (returns empty array)
  def test_create_variables_with_nil
    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1/variables')
      .with(body: '[]')
      .to_return(status: 201, body: '[]', headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.create_variables('exec-1', nil)

    assert_equal [], result
  end

  # Branch coverage: signal_event with empty variables
  def test_signal_event_with_empty_variables
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/executions/exec-1')
      .with(body: { action: 'signalEventReceived', signalName: 'mySignal' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    result = @client.executions.signal_event('exec-1', 'mySignal', variables: {})

    assert_equal({}, result)
  end
end

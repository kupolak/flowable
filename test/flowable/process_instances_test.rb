# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class ProcessInstancesTest < Minitest::Test
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

  def test_list_process_instances
    response = {
      data: [
        { id: 'proc-1', processDefinitionKey: 'testProcess', suspended: false }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list

    assert_equal 1, result['total']
    assert_equal 'proc-1', result['data'][0]['id']
  end

  def test_start_process_by_key
    request_body = {
      processDefinitionKey: 'testProcess',
      businessKey: 'BK-001',
      variables: [
        { name: 'customer', value: 'Acme', type: 'string' }
      ]
    }

    response = {
      id: 'proc-123',
      processDefinitionKey: 'testProcess',
      businessKey: 'BK-001'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_key(
      'testProcess',
      variables: { customer: 'Acme' },
      business_key: 'BK-001'
    )

    assert_equal 'proc-123', result['id']
  end

  def test_get_process_instance
    response = { id: 'proc-1', processDefinitionKey: 'testProcess', suspended: false }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.get('proc-1')

    assert_equal 'proc-1', result['id']
  end

  def test_delete_process_instance
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1')
      .to_return(status: 204)

    result = @client.process_instances.delete('proc-1')

    assert result
  end

  def test_suspend_process_instance
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1')
      .with(body: { action: 'suspend' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.suspend('proc-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1'
  end

  def test_activate_process_instance
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1')
      .with(body: { action: 'activate' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.activate('proc-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1'
  end

  def test_get_variables
    response = [
      { name: 'customer', value: 'Acme', type: 'string' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.variables('proc-1')

    assert_equal 1, result.length
    assert_equal 'customer', result[0]['name']
  end

  def test_set_variables
    request_body = [
      { name: 'status', value: 'processing', type: 'string' }
    ]

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.set_variables('proc-1', { status: 'processing' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables'
  end

  def test_get_diagram
    png_data = 'PNG_BINARY_DATA'

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/diagram')
      .to_return(status: 200, body: png_data, headers: { 'Content-Type' => 'image/png' })

    result = @client.process_instances.diagram('proc-1')

    assert_equal 'PNG_BINARY_DATA', result
  end

  def test_get_identity_links
    response = [
      { user: 'kermit', type: 'starter' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.identity_links('proc-1')

    assert_equal 1, result.length
    assert_equal 'starter', result[0]['type']
  end

  def test_start_by_id
    request_body = {
      processDefinitionId: 'testProcess:1:123',
      businessKey: 'BK-002',
      variables: [{ name: 'amount', value: 100, type: 'long' }]
    }
    response = { id: 'proc-456', processDefinitionId: 'testProcess:1:123' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_id('testProcess:1:123', variables: { amount: 100 }, business_key: 'BK-002')

    assert_equal 'proc-456', result['id']
  end

  def test_query_process_instances
    query = { processDefinitionKey: 'testProcess' }
    response = { data: [], total: 0 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/process-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.query(query)

    assert_equal 0, result['total']
  end

  def test_add_involved_user
    request_body = { userId: 'kermit', type: 'participant' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.add_involved_user('proc-1', 'kermit')

    assert_requested :post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/identitylinks'
  end

  def test_remove_involved_user
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/identitylinks/users/kermit/participant')
      .to_return(status: 204)

    result = @client.process_instances.remove_involved_user('proc-1', 'kermit', 'participant')

    assert result
  end

  def test_get_single_variable
    response = { name: 'customer', value: 'Acme', type: 'string' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables/customer')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.variable('proc-1', 'customer')

    assert_equal 'Acme', result['value']
  end

  def test_create_variables
    request_body = [{ name: 'newVar', value: 'test', type: 'string' }]

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.create_variables('proc-1', { newVar: 'test' })

    assert_requested :post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables'
  end

  def test_update_variable
    request_body = { name: 'status', value: 'done', type: 'string' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables/status')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.process_instances.update_variable('proc-1', 'status', 'done')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables/status'
  end

  def test_delete_variable
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1/variables/oldVar')
      .to_return(status: 204)

    result = @client.process_instances.delete_variable('proc-1', 'oldVar')

    assert result
  end

  # Branch coverage tests

  def test_list_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(query: hash_including('tenantId' => 'tenant-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_list_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  def test_list_with_super_process_instance_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(query: hash_including('superProcessInstanceId' => 'parent-1'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list(superProcessInstanceId: 'parent-1')

    assert_equal 0, result['total']
  end

  def test_start_by_id_with_business_key_and_return_vars
    request_body = {
      processDefinitionId: 'def-1',
      businessKey: 'BK-001',
      returnVariables: true
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-1"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_id('def-1', business_key: 'BK-001', return_variables: true)

    assert_equal 'proc-1', result['id']
  end

  def test_start_by_key_with_business_key
    request_body = {
      processDefinitionKey: 'myProcess',
      businessKey: 'BK-002'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-2"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_key('myProcess', business_key: 'BK-002')

    assert_equal 'proc-2', result['id']
  end

  def test_start_by_key_with_tenant_id
    request_body = {
      processDefinitionKey: 'myProcess',
      tenantId: 'tenant-1'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-3"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_key('myProcess', tenant_id: 'tenant-1')

    assert_equal 'proc-3', result['id']
  end

  def test_start_by_id_without_business_key
    request_body = {
      processDefinitionId: 'def-1'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-4"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_id('def-1')

    assert_equal 'proc-4', result['id']
  end

  def test_query_process_instances
    query = { processDefinitionKey: 'myProcess' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/query/process-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.query(query)

    assert_equal 0, result['total']
  end

  # Branch coverage: start_by_key with return_variables
  def test_start_by_key_with_return_variables
    request_body = {
      processDefinitionKey: 'myProcess',
      returnVariables: true
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-5"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_key('myProcess', return_variables: true)

    assert_equal 'proc-5', result['id']
  end

  # Branch coverage: start_by_id with return_variables
  def test_start_by_id_with_return_variables
    request_body = {
      processDefinitionId: 'def-1',
      returnVariables: true
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"proc-6"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.start_by_id('def-1', return_variables: true)

    assert_equal 'proc-6', result['id']
  end

  def test_list_with_include_process_variables
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(query: hash_including('includeProcessVariables' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list(includeProcessVariables: true)

    assert_equal 0, result['total']
  end

  def test_list_with_suspended
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/runtime/process-instances')
      .with(query: hash_including('suspended' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_instances.list(suspended: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: delete with delete_reason
  def test_delete_with_delete_reason
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/runtime/process-instances/proc-1')
      .with(query: { deleteReason: 'Test deletion' })
      .to_return(status: 204)

    result = @client.process_instances.delete('proc-1', delete_reason: 'Test deletion')

    assert result
  end
end
# 2025-10-07T09:28:47Z - Implement caching for fetched models
# 2025-10-29T14:17:46Z - Align method names with case_definitions
# 2025-11-18T08:28:01Z - Add script to create flowable.png (already added)
# 2025-10-08T09:15:08Z - Implement caching for fetched models
# 2025-10-31T15:30:22Z - Align method names with case_definitions
# 2025-11-25T12:16:34Z - Add script to create flowable.png (already added)

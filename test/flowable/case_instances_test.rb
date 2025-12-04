# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class CaseInstancesTest < Minitest::Test
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

  def test_list_case_instances
    response = {
      data: [
        { id: 'case-1', state: 'active', caseDefinitionName: 'Test Case' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.list

    assert_equal 1, result['total']
    assert_equal 'case-1', result['data'][0]['id']
  end

  def test_start_case_by_key
    request_body = {
      caseDefinitionKey: 'testCase',
      businessKey: 'BK-001',
      variables: [
        { name: 'customer', value: 'Acme', type: 'string' }
      ]
    }

    response = {
      id: 'case-123',
      state: 'active',
      caseDefinitionKey: 'testCase'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_key(
      'testCase',
      variables: { customer: 'Acme' },
      business_key: 'BK-001'
    )

    assert_equal 'case-123', result['id']
    assert_equal 'active', result['state']
  end

  def test_start_case_by_id
    response = { id: 'case-123', state: 'active' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: { caseDefinitionId: 'def-123' }.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_id('def-123')

    assert_equal 'case-123', result['id']
  end

  def test_get_case_instance
    response = { id: 'case-1', state: 'active', businessKey: 'BK-001' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.get('case-1')

    assert_equal 'case-1', result['id']
    assert_equal 'BK-001', result['businessKey']
  end

  def test_delete_case_instance
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1')
      .to_return(status: 204)

    result = @client.case_instances.delete('case-1')

    assert result
  end

  def test_get_variables
    response = [
      { name: 'customer', value: 'Acme', type: 'string' },
      { name: 'amount', value: 1000, type: 'long' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.variables('case-1')

    assert_equal 2, result.length
    assert_equal 'customer', result[0]['name']
  end

  def test_set_variables
    request_body = [
      { name: 'status', value: 'processing', type: 'string' }
    ]

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { status: 'processing' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_stage_overview
    response = [
      { id: 'stage1', name: 'Review', current: true, ended: false },
      { id: 'stage2', name: 'Process', current: false, ended: false }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/stage-overview')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.stage_overview('case-1')

    assert_equal 2, result.length
    assert result[0]['current']
  end

  def test_identity_links
    response = [
      { user: 'kermit', type: 'starter' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.identity_links('case-1')

    assert_equal 1, result.length
    assert_equal 'kermit', result[0]['user']
  end

  def test_query_case_instances
    query = { caseDefinitionKey: 'testCase', state: 'active' }
    response = { data: [{ id: 'case-1' }], total: 1 }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/query/case-instances')
      .with(body: query.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.query(query)

    assert_equal 1, result['total']
  end

  def test_diagram
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/diagram')
      .to_return(status: 200, body: 'PNG_DATA', headers: { 'Content-Type' => 'image/png' })

    result = @client.case_instances.diagram('case-1')

    assert_equal 'PNG_DATA', result
  end

  def test_add_involved_user
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/identitylinks')
      .with(body: { userId: 'kermit', type: 'participant' }.to_json)
      .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.add_involved_user('case-1', 'kermit')

    assert_instance_of Hash, result
  end

  def test_remove_involved_user
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/identitylinks/users/kermit/participant')
      .to_return(status: 204)

    result = @client.case_instances.remove_involved_user('case-1', 'kermit', 'participant')

    assert result
  end

  def test_variable
    response = { name: 'customer', value: 'Acme', type: 'string' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables/customer')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.variable('case-1', 'customer')

    assert_equal 'Acme', result['value']
  end

  def test_create_variables
    request_body = [{ name: 'status', value: 'new', type: 'string' }]

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '[]', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.create_variables('case-1', { status: 'new' })

    assert_instance_of Array, result
  end

  def test_update_variable
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables/status')
      .with(body: { name: 'status', value: 'approved', type: 'string' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.update_variable('case-1', 'status', 'approved')

    assert_instance_of Hash, result
  end

  def test_delete_variable
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables/status')
      .to_return(status: 204)

    result = @client.case_instances.delete_variable('case-1', 'status')

    assert result
  end

  def test_start_case_by_key_with_tenant_id
    request_body = {
      caseDefinitionKey: 'testCase',
      tenantId: 'tenant1',
      returnVariables: true
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.start_by_key('testCase', tenant_id: 'tenant1', return_variables: true)

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances'
  end

  def test_list_with_options
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(query: hash_including(caseDefinitionKey: 'testCase', includeCaseVariables: 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.list(caseDefinitionKey: 'testCase', includeCaseVariables: true)

    assert_equal 0, result['total']
  end

  # Branch coverage tests

  def test_list_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  def test_start_by_id_with_business_key
    request_body = {
      caseDefinitionId: 'def-1',
      businessKey: 'BK-001'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"case-1"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_id('def-1', business_key: 'BK-001')

    assert_equal 'case-1', result['id']
  end

  def test_start_by_id_with_return_variables
    request_body = {
      caseDefinitionId: 'def-1',
      returnVariables: true
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"case-1"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_id('def-1', return_variables: true)

    assert_equal 'case-1', result['id']
  end

  def test_start_by_key_with_business_key
    request_body = {
      caseDefinitionKey: 'testCase',
      businessKey: 'BK-002'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: '{"id":"case-2"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_key('testCase', business_key: 'BK-002')

    assert_equal 'case-2', result['id']
  end

  def test_start_by_id_with_variables
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: hash_including('caseDefinitionId' => 'def-1'))
      .to_return(status: 201, body: '{"id":"case-3"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_id('def-1', variables: { foo: 'bar' })

    assert_equal 'case-3', result['id']
  end

  def test_start_by_key_with_variables
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: hash_including('caseDefinitionKey' => 'testCase'))
      .to_return(status: 201, body: '{"id":"case-4"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_key('testCase', variables: { myVar: 'value' })

    assert_equal 'case-4', result['id']
  end
end
# 2025-10-06T09:46:21Z - Add tenant_id filtering
# 2025-10-28T08:44:02Z - Add filtering by tenant and key
# 2025-11-17T11:45:34Z - Add integration tests for CLI
# 2025-10-07T11:03:28Z - Add tenant_id filtering
# 2025-10-29T14:56:40Z - Add filtering by tenant and key
# 2025-11-21T09:51:28Z - Add integration tests for CLI

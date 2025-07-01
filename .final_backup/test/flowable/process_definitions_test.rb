# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class ProcessDefinitionsTest < Minitest::Test
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

  def test_list_process_definitions
    response = {
      data: [
        { id: 'def-1', key: 'testProcess', name: 'Test Process', version: 1 }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list

    assert_equal 1, result['total']
    assert_equal 'testProcess', result['data'][0]['key']
  end

  def test_list_latest_definitions
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions?latest=true')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(latest: true)

    assert_equal 0, result['total']
  end

  def test_get_process_definition
    response = { id: 'def-1', key: 'testProcess', name: 'Test Process', deploymentId: 'dep-1' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.get('def-1')

    assert_equal 'def-1', result['id']
    assert_equal 'testProcess', result['key']
  end

  def test_get_resource_content
    bpmn_content = '<?xml version="1.0" encoding="UTF-8"?><process/>'

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/resourcedata')
      .to_return(status: 200, body: bpmn_content, headers: { 'Content-Type' => 'application/xml' })

    result = @client.process_definitions.resource_content('def-1')

    assert_includes result, '<?xml'
  end

  def test_get_model
    response = { id: 'def-1', name: 'Test Process', flowElements: [] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/model')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.model('def-1')

    assert_equal 'def-1', result['id']
    assert result.key?('flowElements')
  end

  def test_get_diagram
    png_data = 'PNG_BINARY_DATA'

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/image')
      .to_return(status: 200, body: png_data, headers: { 'Content-Type' => 'image/png' })

    result = @client.process_definitions.diagram('def-1')

    assert_equal 'PNG_BINARY_DATA', result
  end

  def test_get_identity_links
    response = [
      { user: 'kermit', type: 'candidate' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.identity_links('def-1')

    assert_equal 1, result.length
    assert_equal 'candidate', result[0]['type']
  end

  def test_suspend_process_definition
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: { action: 'suspend', includeProcessInstances: false }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.process_definitions.suspend('def-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1'
  end

  def test_activate_process_definition
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: { action: 'activate', includeProcessInstances: false }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.process_definitions.activate('def-1')

    assert_requested :put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1'
  end

  def test_get_by_key
    response = {
      data: [{ id: 'def-1', key: 'testProcess', version: 1 }],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions?key=testProcess&latest=true')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.get_by_key('testProcess')

    assert_equal 'def-1', result['id']
  end

  def test_update_category
    response = { id: 'def-1', category: 'newCategory' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: { category: 'newCategory' }.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.update_category('def-1', 'newCategory')

    assert_equal 'newCategory', result['category']
  end

  def test_add_candidate_user
    request_body = { user: 'kermit' }
    response = { user: 'kermit', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.add_candidate_user('def-1', 'kermit')

    assert_equal 'kermit', result['user']
  end

  def test_add_candidate_group
    request_body = { group: 'managers' }
    response = { group: 'managers', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.add_candidate_group('def-1', 'managers')

    assert_equal 'managers', result['group']
  end

  def test_remove_candidate
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1/identitylinks/users/kermit')
      .to_return(status: 204)

    result = @client.process_definitions.remove_candidate('def-1', 'users', 'kermit')

    assert result
  end

  # Branch coverage tests

  def test_list_with_version
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('version' => '2'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(version: 2)

    assert_equal 0, result['total']
  end

  def test_list_with_latest
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('latest' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(latest: true)

    assert_equal 0, result['total']
  end

  def test_list_with_suspended
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('suspended' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(suspended: true)

    assert_equal 0, result['total']
  end

  def test_list_with_startable_by_user
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('startableByUser' => 'kermit'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(startableByUser: 'kermit')

    assert_equal 0, result['total']
  end

  def test_get_by_key_with_tenant_id
    response = { data: [{ id: 'def-1', key: 'myProcess' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('key' => 'myProcess', 'latest' => 'true', 'tenantId' => 'tenant-1'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.get_by_key('myProcess', tenant_id: 'tenant-1')

    assert_equal 'def-1', result['id']
  end

  def test_get_by_key_not_found
    response = { data: [] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('key' => 'nonexistent', 'latest' => 'true'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.get_by_key('nonexistent')

    assert_nil result
  end

  def test_suspend
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: hash_including('action' => 'suspend'))
      .to_return(status: 200, body: '{"id":"def-1","suspended":true}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.suspend('def-1')

    assert result['suspended']
  end

  def test_activate
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: hash_including('action' => 'activate'))
      .to_return(status: 200, body: '{"id":"def-1","suspended":false}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.activate('def-1')

    refute result['suspended']
  end

  # Branch coverage: suspend/activate with date parameter
  def test_suspend_with_date
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: hash_including('action' => 'suspend', 'date' => '2024-12-01'))
      .to_return(status: 200, body: '{"id":"def-1","suspended":true}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.suspend('def-1', date: '2024-12-01')

    assert result['suspended']
  end

  def test_activate_with_date
    stub_request(:put, 'http://localhost:8080/flowable-rest/service/repository/process-definitions/def-1')
      .with(body: hash_including('action' => 'activate', 'date' => '2024-12-01'))
      .to_return(status: 200, body: '{"id":"def-1","suspended":false}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.activate('def-1', date: '2024-12-01')

    refute result['suspended']
  end

  def test_list_with_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('withoutTenantId' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  # Branch coverage: get_by_key when result['data'] is nil (safe navigation else branch)
  def test_get_by_key_with_nil_data
    # API returns response without 'data' key
    response = { total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/process-definitions')
      .with(query: hash_including('key' => 'unknown', 'latest' => 'true'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.process_definitions.get_by_key('unknown')

    assert_nil result
  end
end
# 2025-10-07T08:56:27Z - Add example fetching model in examples/
# 2025-10-29T11:26:20Z - Add endpoint to activate/deactivate versions
# 2025-11-18T14:40:39Z - Fix file permissions for bin/flowable
# 2025-10-08T14:19:34Z - Add example fetching model in examples/
# 2025-10-31T15:30:56Z - Add endpoint to activate/deactivate versions
# 2025-11-24T13:21:47Z - Fix file permissions for bin/flowable

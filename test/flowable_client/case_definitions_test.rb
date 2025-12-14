# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable'

class CaseDefinitionsTest < Minitest::Test
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

  def test_list_case_definitions
    response = {
      data: [
        { id: 'def-1', key: 'testCase', name: 'Test Case', version: 1 }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.list

    assert_equal 1, result['total']
    assert_equal 'testCase', result['data'][0]['key']
  end

  def test_list_case_definitions_with_filters
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions?latest=true&key=orderCase')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.list(key: 'orderCase', latest: true)

    assert_equal 0, result['total']
  end

  def test_get_case_definition
    response = { id: 'def-1', key: 'testCase', name: 'Test Case', version: 1, deploymentId: 'dep-1' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.get('def-1')

    assert_equal 'def-1', result['id']
    assert_equal 'testCase', result['key']
  end

  def test_get_resource_content
    cmmn_content = '<?xml version="1.0" encoding="UTF-8"?><case/>'

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/resourcedata')
      .to_return(status: 200, body: cmmn_content, headers: { 'Content-Type' => 'application/xml' })

    result = @client.case_definitions.resource_content('def-1')

    assert_includes result, '<?xml'
  end

  def test_get_model
    response = { id: 'def-1', name: 'Test Case', planModel: {} }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/model')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.model('def-1')

    assert_equal 'def-1', result['id']
    assert result.key?('planModel')
  end

  def test_get_identity_links
    response = [
      { user: 'kermit', type: 'starter' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.identity_links('def-1')

    assert_equal 1, result.length
    assert_equal 'starter', result[0]['type']
  end

  def test_get_by_key
    response = {
      data: [{ id: 'def-1', key: 'testCase', version: 1 }],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions?key=testCase&latest=true')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.get_by_key('testCase')

    assert_equal 'def-1', result['id']
  end

  def test_update_category
    response = { id: 'def-1', category: 'newCategory' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1')
      .with(body: { category: 'newCategory' }.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.update_category('def-1', 'newCategory')

    assert_equal 'newCategory', result['category']
  end

  def test_add_candidate_user
    request_body = { user: 'kermit' }
    response = { user: 'kermit', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.add_candidate_user('def-1', 'kermit')

    assert_equal 'kermit', result['user']
  end

  def test_add_candidate_group
    request_body = { groupId: 'managers' }
    response = { group: 'managers', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.add_candidate_group('def-1', 'managers')

    assert_equal 'managers', result['group']
  end

  def test_remove_candidate
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions/def-1/identitylinks/users/kermit')
      .to_return(status: 204)

    result = @client.case_definitions.remove_candidate('def-1', 'users', 'kermit')

    assert result
  end

  # Branch coverage tests

  def test_list_with_version
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('version' => '2'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.list(version: 2)

    assert_equal 0, result['total']
  end

  def test_list_with_latest_false
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('latest' => 'false'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.list(latest: false)

    assert_equal 0, result['total']
  end

  def test_list_with_suspended_true
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('suspended' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.list(suspended: true)

    assert_equal 0, result['total']
  end

  def test_get_by_key_with_tenant_id
    response = { data: [{ id: 'def-1', key: 'myCase' }] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('key' => 'myCase', 'latest' => 'true', 'tenantId' => 'tenant-1'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.get_by_key('myCase', tenant_id: 'tenant-1')

    assert_equal 'def-1', result['id']
  end

  def test_get_by_key_not_found
    response = { data: [] }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('key' => 'nonexistent', 'latest' => 'true'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.get_by_key('nonexistent')

    assert_nil result
  end

  # Branch coverage: get_by_key when result['data'] is nil (safe navigation else branch)
  def test_get_by_key_with_nil_data
    # API returns response without 'data' key
    response = { total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/case-definitions')
      .with(query: hash_including('key' => 'unknown', 'latest' => 'true'))
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.case_definitions.get_by_key('unknown')

    assert_nil result
  end
end
# 2025-10-07T13:10:58Z - Support business_key and variables on start
# 2025-10-29T10:21:59Z - Add pagination for process instances
# 2025-11-19T11:59:13Z - Add script to run examples locally
# 2025-10-09T07:52:10Z - Support business_key and variables on start
# 2025-10-31T14:01:27Z - Add pagination for process instances
# 2025-11-26T11:40:47Z - Add script to run examples locally

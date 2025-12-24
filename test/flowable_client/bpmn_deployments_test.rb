# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class BpmnDeploymentsTest < Minitest::Test
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

  def test_list_deployments
    response = {
      data: [
        { id: 'dep-1', name: 'TestDeployment', deploymentTime: '2024-01-15T10:00:00Z' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list

    assert_equal 1, result['total']
    assert_equal 'dep-1', result['data'][0]['id']
  end

  def test_get_deployment
    response = { id: 'dep-1', name: 'TestDeployment', category: 'test' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.get('dep-1')

    assert_equal 'dep-1', result['id']
    assert_equal 'test', result['category']
  end

  def test_delete_deployment
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1')
      .to_return(status: 204)

    result = @client.bpmn_deployments.delete('dep-1')

    assert result
  end

  def test_get_resources
    response = [
      { id: 'res-1', url: 'http://localhost:8080/test.bpmn', dataUrl: 'http://localhost:8080/data' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1/resources')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.resources('dep-1')

    assert_equal 1, result.length
    assert_equal 'res-1', result[0]['id']
  end

  def test_get_resource_content
    bpmn_content = '<?xml version="1.0" encoding="UTF-8"?><process/>'

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1/resourcedata/test.bpmn')
      .to_return(status: 200, body: bpmn_content, headers: { 'Content-Type' => 'application/xml' })

    result = @client.bpmn_deployments.resource_content('dep-1', 'test.bpmn')

    assert_includes result, '<?xml'
  end

  def test_resource
    response = { id: 'test.bpmn', mediaType: 'text/xml' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1/resources/test.bpmn')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.resource('dep-1', 'test.bpmn')

    assert_equal 'test.bpmn', result['id']
  end

  def test_resource_data
    xml_content = '<?xml version="1.0"?><definitions/>'

    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1/resourcedata/test.bpmn')
      .to_return(status: 200, body: xml_content, headers: { 'Content-Type' => 'text/xml' })

    result = @client.bpmn_deployments.resource_data('dep-1', 'test.bpmn')

    assert_equal xml_content, result
  end

  # Branch coverage tests

  def test_list_with_name
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .with(query: hash_including('name' => 'MyDeployment'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(name: 'MyDeployment')

    assert_equal 0, result['total']
  end

  def test_list_with_name_like
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .with(query: hash_including('nameLike' => '%test%'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(nameLike: '%test%')

    assert_equal 0, result['total']
  end

  def test_list_with_category
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .with(query: hash_including('category' => 'orders'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(category: 'orders')

    assert_equal 0, result['total']
  end

  def test_list_with_category_not_equals
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(categoryNotEquals: 'draft')

    assert_equal 0, result['total']
  end

  def test_list_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .with(query: { tenantId: 'tenant-1' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_list_without_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .with(query: { withoutTenantId: 'true' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.bpmn_deployments.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  def test_delete_without_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1')
      .to_return(status: 204)

    result = @client.bpmn_deployments.delete('dep-1', cascade: false)

    assert result
  end

  # Branch coverage: create method with optional parameters
  def test_create_with_name_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    require 'tempfile'
    file = Tempfile.new(['test', '.bpmn'])
    file.write('<?xml version="1.0"?><process/>')
    file.close

    result = @client.bpmn_deployments.create(file.path, name: 'MyBpmnDeployment')

    assert_equal 'dep-1', result['id']
    file.unlink
  end

  def test_create_with_tenant_id_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    require 'tempfile'
    file = Tempfile.new(['test', '.bpmn'])
    file.write('<?xml version="1.0"?><process/>')
    file.close

    result = @client.bpmn_deployments.create(file.path, tenant_id: 'tenant-1')

    assert_equal 'dep-1', result['id']
    file.unlink
  end

  def test_create_with_category_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/service/repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    require 'tempfile'
    file = Tempfile.new(['test', '.bpmn'])
    file.write('<?xml version="1.0"?><process/>')
    file.close

    result = @client.bpmn_deployments.create(file.path, category: 'orders')

    assert_equal 'dep-1', result['id']
    file.unlink
  end

  # Branch coverage: delete with cascade
  def test_delete_with_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/service/repository/deployments/dep-1')
      .with(query: { cascade: 'true' })
      .to_return(status: 204)

    result = @client.bpmn_deployments.delete('dep-1', cascade: true)

    assert result
  end
end

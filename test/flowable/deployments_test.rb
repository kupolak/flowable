# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class DeploymentsTest < Minitest::Test
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
        { id: 'deploy-1', name: 'test-deployment', deploymentTime: '2024-01-01T10:00:00Z' }
      ],
      total: 1,
      start: 0,
      size: 10
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list

    assert_equal 1, result['total']
    assert_equal 'deploy-1', result['data'][0]['id']
  end

  def test_list_deployments_with_filters
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: { name: 'test', tenantId: 'acme' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list(name: 'test', tenantId: 'acme')

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments',
                     query: { name: 'test', tenantId: 'acme' }
  end

  def test_get_deployment
    response = { id: 'deploy-1', name: 'test-deployment' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.get('deploy-1')

    assert_equal 'deploy-1', result['id']
    assert_equal 'test-deployment', result['name']
  end

  def test_delete_deployment
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1')
      .to_return(status: 204)

    result = @client.deployments.delete('deploy-1')

    assert result
  end

  def test_list_deployment_resources
    response = [
      { id: 'test.cmmn.xml', mediaType: 'text/xml', type: 'caseDefinition' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1/resources')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.resources('deploy-1')

    assert_equal 1, result.length
    assert_equal 'test.cmmn.xml', result[0]['id']
  end

  def test_delete_deployment_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1')
      .with(query: { cascade: 'true' })
      .to_return(status: 204)

    result = @client.deployments.delete('deploy-1', cascade: true)

    assert result
  end

  def test_resource
    response = { id: 'test.cmmn.xml', mediaType: 'text/xml' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1/resources/test.cmmn.xml')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.resource('deploy-1', 'test.cmmn.xml')

    assert_equal 'test.cmmn.xml', result['id']
  end

  def test_resource_data
    xml_content = '<?xml version="1.0"?><definitions/>'

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1/resourcedata/test.cmmn.xml')
      .to_return(status: 200, body: xml_content, headers: { 'Content-Type' => 'text/xml' })

    result = @client.deployments.resource_data('deploy-1', 'test.cmmn.xml')

    assert_equal xml_content, result
  end

  def test_list_deployments_with_name_like
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: { nameLike: '%test%' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list(nameLike: '%test%')

    assert_equal 0, result['total']
  end

  def test_list_deployments_with_category
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: { category: 'orders' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list(category: 'orders')

    assert_equal 0, result['total']
  end

  def test_list_deployments_with_tenant_id
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: { tenantId: 'tenant-1' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list(tenantId: 'tenant-1')

    assert_equal 0, result['total']
  end

  def test_list_deployments_without_tenant
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: { withoutTenantId: 'true' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list(withoutTenantId: true)

    assert_equal 0, result['total']
  end

  def test_delete_with_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/deploy-1')
      .with(query: { cascade: 'true' })
      .to_return(status: 204)

    result = @client.deployments.delete('deploy-1', cascade: true)

    assert result
  end

  # Branch coverage: create method with optional parameters
  def test_create_with_name_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    # Create a temp file for the test
    require 'tempfile'
    file = Tempfile.new(['test', '.cmmn.xml'])
    file.write('<?xml version="1.0"?><definitions/>')
    file.close

    result = @client.deployments.create(file.path, name: 'MyDeployment')

    assert_equal 'dep-1', result['id']
    file.unlink
  end

  def test_create_with_tenant_id_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    require 'tempfile'
    file = Tempfile.new(['test', '.cmmn.xml'])
    file.write('<?xml version="1.0"?><definitions/>')
    file.close

    result = @client.deployments.create(file.path, tenant_id: 'tenant-1')

    assert_equal 'dep-1', result['id']
    file.unlink
  end

  def test_create_with_category_param
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 201, body: '{"id":"dep-1"}', headers: { 'Content-Type' => 'application/json' })

    require 'tempfile'
    file = Tempfile.new(['test', '.cmmn.xml'])
    file.write('<?xml version="1.0"?><definitions/>')
    file.close

    result = @client.deployments.create(file.path, category: 'orders')

    assert_equal 'dep-1', result['id']
    file.unlink
  end
end

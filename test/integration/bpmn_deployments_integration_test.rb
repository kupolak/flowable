# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class BpmnDeploymentsIntegrationTest < IntegrationTest
  def setup
    super
    @created_deployments = []
  end

  def teardown
    @created_deployments.each do |dep_id|
      client.bpmn_deployments.delete(dep_id) rescue nil
    end
  end

  def test_list_deployments
    result = client.bpmn_deployments.list

    assert result.key?('data')
    assert result.key?('total')
  end

  def test_deploy_bpmn_file
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    result = client.bpmn_deployments.create(file.path, name: 'BPMN Integration Test')
    @created_deployments << result['id']

    assert result['id']
    # Flowable may use filename or provided name depending on version
    assert result['name']
  ensure
    file&.unlink
  end

  def test_get_deployment
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    created = client.bpmn_deployments.create(file.path, name: 'Get BPMN Test')
    @created_deployments << created['id']

    result = client.bpmn_deployments.get(created['id'])

    assert_equal created['id'], result['id']
  ensure
    file&.unlink
  end

  def test_delete_deployment
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    created = client.bpmn_deployments.create(file.path, name: 'Delete BPMN Test')

    result = client.bpmn_deployments.delete(created['id'])

    assert result

    assert_raises(Flowable::NotFoundError) do
      client.bpmn_deployments.get(created['id'])
    end
  ensure
    file&.unlink
  end

  def test_get_deployment_resources
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    created = client.bpmn_deployments.create(file.path)
    @created_deployments << created['id']

    resources = client.bpmn_deployments.resources(created['id'])

    assert_kind_of Array, resources
    assert_operator resources.length, :>, 0
  ensure
    file&.unlink
  end
end

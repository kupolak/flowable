# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class DeploymentsIntegrationTest < IntegrationTest
  def setup
    super
    @created_deployments = []
  end

  def teardown
    # Cleanup created deployments
    @created_deployments.each do |dep_id|
      client.deployments.delete(dep_id) rescue nil
    end
  end

  def test_list_deployments
    result = client.deployments.list

    assert result.key?('data')
    assert result.key?('total')
    assert_kind_of Array, result['data']
  end

  def test_deploy_cmmn_file
    # Create temp file with CMMN content
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    result = client.deployments.create(file.path)
    @created_deployments << result['id']

    assert result['id']
    assert result['name'] # Name is generated from filename
  ensure
    file&.unlink
  end

  def test_get_deployment
    # First create a deployment
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    created = client.deployments.create(file.path)
    @created_deployments << created['id']

    # Now get it
    result = client.deployments.get(created['id'])

    assert_equal created['id'], result['id']
    assert result['name']
  ensure
    file&.unlink
  end

  def test_delete_deployment
    # First create a deployment
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    created = client.deployments.create(file.path, name: 'Delete Test')

    # Delete it
    result = client.deployments.delete(created['id'])

    assert result

    # Verify it's gone
    assert_raises(Flowable::NotFoundError) do
      client.deployments.get(created['id'])
    end
  ensure
    file&.unlink
  end

  def test_get_deployment_resources
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    created = client.deployments.create(file.path)
    @created_deployments << created['id']

    resources = client.deployments.resources(created['id'])

    assert_kind_of Array, resources
    assert_operator resources.length, :>, 0
  ensure
    file&.unlink
  end

  def test_list_with_filters
    # Create deployment with specific name
    file = Tempfile.new(['filter-test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    created = client.deployments.create(file.path)
    @created_deployments << created['id']

    # Search by name pattern (deployment name is based on temp file name)
    result = client.deployments.list(nameLike: '%filter-test%')

    assert_operator result['total'], :>=, 1
  ensure
    file&.unlink
  end
end

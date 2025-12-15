# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class ProcessDefinitionsIntegrationTest < IntegrationTest
  def setup
    super
    @deployment_id = deploy_test_process
  end

  def teardown
    client.bpmn_deployments.delete(@deployment_id) rescue nil
  end

  def deploy_test_process
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    result = client.bpmn_deployments.create(file.path, name: 'ProcessDefTest')
    file.unlink
    result['id']
  end

  def test_list_process_definitions
    result = client.process_definitions.list

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_list_latest_process_definitions
    result = client.process_definitions.list(latest: true)

    assert result.key?('data')
  end

  def test_get_process_definition
    definitions = client.process_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    result = client.process_definitions.get(definition['id'])

    assert_equal definition['id'], result['id']
    assert_equal 'testProcess', result['key']
  end

  def test_get_resource_content
    definitions = client.process_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    content = client.process_definitions.resource_content(definition['id'])

    assert_includes content, 'testProcess'
    assert_includes content, 'BPMN'
  end

  def test_get_model
    definitions = client.process_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    model = client.process_definitions.model(definition['id'])

    assert model.key?('mainProcess') || model.key?('processes')
  end

  def test_suspend_and_activate_definition
    definitions = client.process_definitions.list(deploymentId: @deployment_id)
    definition = definitions['data'].first

    # Suspend
    client.process_definitions.suspend(definition['id'])
    suspended = client.process_definitions.get(definition['id'])

    assert suspended['suspended']

    # Activate
    client.process_definitions.activate(definition['id'])
    activated = client.process_definitions.get(definition['id'])

    refute activated['suspended']
  end
end
# 2025-10-14T14:19:27Z - Add unit tests for tasks
# 2025-11-05T10:17:08Z - Add retry on conflict during completion
# 2025-11-25T12:11:28Z - Add test helpers to mock Flowable responses
# 2025-10-14T08:03:05Z - Add unit tests for tasks
# 2025-11-07T14:00:42Z - Add retry on conflict during completion
# 2025-12-02T10:49:50Z - Add test helpers to mock Flowable responses

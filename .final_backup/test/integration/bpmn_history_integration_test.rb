# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class BpmnHistoryIntegrationTest < IntegrationTest
  def setup
    super
    @deployment_id = deploy_test_process
    @process_instances = []
  end

  def teardown
    @process_instances&.each do |id|
      client.process_instances.delete(id) rescue nil
    end
    client.bpmn_deployments.delete(@deployment_id) rescue nil if @deployment_id
  end

  def deploy_test_process
    file = Tempfile.new(['test', '.bpmn20.xml'])
    file.write(sample_bpmn_content)
    file.close

    result = client.bpmn_deployments.create(file.path, name: 'BpmnHistoryTest')
    file.unlink
    result['id']
  end

  def test_list_historic_process_instances
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.bpmn_history.process_instances

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_get_historic_process_instance
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.bpmn_history.process_instance(process['id'])

    assert_equal process['id'], result['id']
  end

  def test_list_historic_tasks
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.bpmn_history.tasks

    assert result.key?('data')
  end

  def test_list_historic_activities
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.bpmn_history.activities

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_list_historic_variables
    process = client.process_instances.start_by_key('testProcess', variables: { histVar: 'histValue' })
    @process_instances << process['id']

    result = client.bpmn_history.variables(processInstanceId: process['id'])

    assert result.key?('data')
  end

  def test_list_historic_details
    process = client.process_instances.start_by_key('testProcess', variables: { detailVar: 'detailValue' })
    @process_instances << process['id']

    result = client.bpmn_history.details

    assert result.key?('data')
  end

  def test_filter_finished_processes
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    # Query unfinished only (our process has a user task, so it's not finished)
    result = client.bpmn_history.process_instances(finished: false)

    assert_operator result['total'], :>=, 1
  end
end
# 2025-10-14T12:19:36Z - Add get task details
# 2025-11-04T14:51:39Z - Support formProperties for tasks
# 2025-11-24T12:37:23Z - Add integration tests with local Docker
# 2025-10-10T11:49:09Z - Add get task details
# 2025-11-04T14:57:57Z - Support formProperties for tasks
# 2025-11-28T10:04:40Z - Add integration tests with local Docker

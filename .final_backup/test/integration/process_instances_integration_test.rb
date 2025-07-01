# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class ProcessInstancesIntegrationTest < IntegrationTest
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

    result = client.bpmn_deployments.create(file.path, name: 'ProcessInstanceTest')
    file.unlink
    result['id']
  end

  def test_list_process_instances
    result = client.process_instances.list

    assert result.key?('data')
    assert result.key?('total')
  end

  def test_start_process_by_key
    result = client.process_instances.start_by_key('testProcess')
    @process_instances << result['id']

    assert result['id']
    # API returns processDefinitionId, not processDefinitionKey directly
    assert result['processDefinitionId']
    assert_includes result['processDefinitionId'], 'testProcess'
  end

  def test_start_process_with_variables
    result = client.process_instances.start_by_key(
      'testProcess',
      variables: { order_id: 'ORD-001', amount: 500 },
      business_key: 'PROCESS-001'
    )
    @process_instances << result['id']

    assert result['id']
    assert_equal 'PROCESS-001', result['businessKey']
  end

  def test_get_process_instance
    created = client.process_instances.start_by_key('testProcess')
    @process_instances << created['id']

    result = client.process_instances.get(created['id'])

    assert_equal created['id'], result['id']
  end

  def test_delete_process_instance
    created = client.process_instances.start_by_key('testProcess')

    result = client.process_instances.delete(created['id'])

    assert result

    assert_raises(Flowable::NotFoundError) do
      client.process_instances.get(created['id'])
    end
  end

  def test_suspend_and_activate_process
    created = client.process_instances.start_by_key('testProcess')
    @process_instances << created['id']

    # Suspend
    client.process_instances.suspend(created['id'])
    suspended = client.process_instances.get(created['id'])

    assert suspended['suspended']

    # Activate
    client.process_instances.activate(created['id'])
    activated = client.process_instances.get(created['id'])

    refute activated['suspended']
  end

  def test_get_and_set_variables
    created = client.process_instances.start_by_key('testProcess', variables: { initial: 'value' })
    @process_instances << created['id']

    vars = client.process_instances.variables(created['id'])

    assert_kind_of Array, vars

    client.process_instances.set_variables(created['id'], { newVar: 'newValue' })

    updated_vars = client.process_instances.variables(created['id'])
    var_names = updated_vars.map { |v| v['name'] }

    assert_includes var_names, 'newVar'
  end

  def test_get_identity_links
    created = client.process_instances.start_by_key('testProcess')
    @process_instances << created['id']

    links = client.process_instances.identity_links(created['id'])

    assert_kind_of Array, links
  end
end
# 2025-10-15T09:02:43Z - Add pagination and sorting for tasks
# 2025-11-05T15:43:17Z - Add audit logging for task actions
# 2025-11-25T10:43:37Z - Stabilize flaky tests
# 2025-10-14T12:48:40Z - Add pagination and sorting for tasks
# 2025-11-07T11:53:33Z - Add audit logging for task actions
# 2025-12-03T10:13:59Z - Stabilize flaky tests

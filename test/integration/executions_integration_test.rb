# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class ExecutionsIntegrationTest < IntegrationTest
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

    result = client.bpmn_deployments.create(file.path, name: 'ExecutionsTest')
    file.unlink
    result['id']
  end

  def test_list_executions
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.executions.list

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_list_executions_by_process_instance
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    result = client.executions.list(processInstanceId: process['id'])

    assert_operator result['total'], :>=, 1

    result['data'].each do |exec|
      assert_equal process['id'], exec['processInstanceId']
    end
  end

  def test_get_execution
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    executions = client.executions.list(processInstanceId: process['id'])
    execution = executions['data'].first

    result = client.executions.get(execution['id'])

    assert_equal execution['id'], result['id']
  end

  def test_get_execution_activities
    process = client.process_instances.start_by_key('testProcess')
    @process_instances << process['id']

    executions = client.executions.list(processInstanceId: process['id'])
    execution = executions['data'].first

    activities = client.executions.activities(execution['id'])

    assert_kind_of Array, activities
  end

  def test_get_execution_variables
    process = client.process_instances.start_by_key('testProcess', variables: { execVar: 'execValue' })
    @process_instances << process['id']

    executions = client.executions.list(processInstanceId: process['id'])
    execution = executions['data'].first

    vars = client.executions.variables(execution['id'])

    assert_kind_of Array, vars
  end
end

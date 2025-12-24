# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class HistoryIntegrationTest < IntegrationTest
  def setup
    super
    @deployment_id = deploy_test_case
    @case_instances = []
  end

  def teardown
    @case_instances.each do |id|
      client.case_instances.delete(id) rescue nil
    end
    client.deployments.delete(@deployment_id) rescue nil
  end

  def deploy_test_case
    file = Tempfile.new(['test', '.cmmn'])
    file.write(sample_cmmn_content)
    file.close

    result = client.deployments.create(file.path, name: 'HistoryTest')
    file.unlink
    result['id']
  end

  def create_and_complete_case
    # Start case
    case_instance = client.case_instances.start_by_key('testCase', variables: { customer: 'TestCorp' })

    # Complete task to finish case
    tasks = client.tasks.list(caseInstanceId: case_instance['id'])
    if tasks['total'].positive?
      client.tasks.complete(tasks['data'].first['id'])
    end

    case_instance
  end

  def test_list_historic_case_instances
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    result = client.history.case_instances

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_get_historic_case_instance
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    result = client.history.case_instance(case_instance['id'])

    assert_equal case_instance['id'], result['id']
  end

  def test_list_historic_tasks
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    # Complete task
    tasks = client.tasks.list(caseInstanceId: case_instance['id'])
    if tasks['total'].positive?
      client.tasks.complete(tasks['data'].first['id'])
    end

    # Check history
    result = client.history.tasks

    assert_operator result['total'], :>=, 1
  end

  def test_list_historic_plan_item_instances
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    result = client.history.plan_item_instances

    assert result.key?('data')
  end

  def test_list_historic_variables
    case_instance = client.case_instances.start_by_key('testCase', variables: { historyVar: 'historyValue' })
    @case_instances << case_instance['id']

    result = client.history.variables(caseInstanceId: case_instance['id'])

    assert result.key?('data')
  end

  def test_filter_finished_cases
    # Create and complete a case
    create_and_complete_case

    # Wait a moment for history
    sleep 1

    # Query finished cases
    result = client.history.case_instances(finished: true)

    assert result.key?('data')
  end
end

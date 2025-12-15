# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class PlanItemInstancesIntegrationTest < IntegrationTest
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

    result = client.deployments.create(file.path, name: 'PlanItemTest')
    file.unlink
    result['id']
  end

  def test_list_plan_item_instances
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    result = client.plan_item_instances.list

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_list_by_case_instance
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    result = client.plan_item_instances.list(caseInstanceId: case_instance['id'])

    assert_operator result['total'], :>=, 1

    # All items should belong to our case
    result['data'].each do |item|
      assert_equal case_instance['id'], item['caseInstanceId']
    end
  end

  def test_get_plan_item_instance
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    items = client.plan_item_instances.list(caseInstanceId: case_instance['id'])
    item = items['data'].first

    result = client.plan_item_instances.get(item['id'])

    assert_equal item['id'], result['id']
  end

  def test_plan_item_states
    case_instance = client.case_instances.start_by_key('testCase')
    @case_instances << case_instance['id']

    items = client.plan_item_instances.list(caseInstanceId: case_instance['id'])
    item = items['data'].first

    # Check state is valid
    valid_states = %w[active available completed disabled enabled terminated unavailable waiting]

    assert_includes valid_states, item['state']
  end
end
# 2025-10-14T12:28:36Z - Add create/update task variables
# 2025-11-05T14:34:08Z - Improve candidate user handling in BPMN tasks
# 2025-11-25T15:58:03Z - Add CI job to run tests (if missing)
# 2025-10-14T12:53:48Z - Add create/update task variables
# 2025-11-06T15:32:20Z - Improve candidate user handling in BPMN tasks
# 2025-12-02T13:50:33Z - Add CI job to run tests (if missing)

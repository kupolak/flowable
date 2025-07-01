# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class CaseInstancesIntegrationTest < IntegrationTest
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

    result = client.deployments.create(file.path, name: 'CaseInstanceTest')
    file.unlink
    result['id']
  end

  def test_list_case_instances
    result = client.case_instances.list

    assert result.key?('data')
    assert result.key?('total')
  end

  def test_start_case_by_key
    result = client.case_instances.start_by_key('testCase')
    @case_instances << result['id']

    assert result['id']
    # caseDefinitionKey may or may not be in response depending on Flowable version
    assert result['caseDefinitionId'] || result['caseDefinitionKey']
  end

  def test_start_case_with_variables
    result = client.case_instances.start_by_key(
      'testCase',
      variables: { customer: 'ACME', amount: 1000 },
      business_key: 'ORDER-001'
    )
    @case_instances << result['id']

    assert result['id']
    assert_equal 'ORDER-001', result['businessKey']
  end

  def test_get_case_instance
    created = client.case_instances.start_by_key('testCase')
    @case_instances << created['id']

    result = client.case_instances.get(created['id'])

    assert_equal created['id'], result['id']
  end

  def test_delete_case_instance
    created = client.case_instances.start_by_key('testCase')

    result = client.case_instances.delete(created['id'])

    assert result

    assert_raises(Flowable::NotFoundError) do
      client.case_instances.get(created['id'])
    end
  end

  def test_get_and_set_variables
    created = client.case_instances.start_by_key('testCase', variables: { initial: 'value' })
    @case_instances << created['id']

    # Get variables
    vars = client.case_instances.variables(created['id'])

    assert_kind_of Array, vars

    # Set new variable
    client.case_instances.set_variables(created['id'], { newVar: 'newValue' })

    # Verify
    updated_vars = client.case_instances.variables(created['id'])
    var_names = updated_vars.map { |v| v['name'] }

    assert_includes var_names, 'newVar'
  end

  def test_stage_overview
    created = client.case_instances.start_by_key('testCase')
    @case_instances << created['id']

    # Stage overview may be empty for simple cases
    result = client.case_instances.stage_overview(created['id'])

    assert_kind_of Array, result
  end

  def test_identity_links
    created = client.case_instances.start_by_key('testCase')
    @case_instances << created['id']

    links = client.case_instances.identity_links(created['id'])

    assert_kind_of Array, links
  end

  def test_list_with_filters
    created = client.case_instances.start_by_key('testCase', business_key: 'FILTER-TEST-123')
    @case_instances << created['id']

    result = client.case_instances.list(businessKey: 'FILTER-TEST-123')

    assert_operator result['total'], :>=, 1
  end
end
# 2025-10-14T07:08:56Z - Add complete task with variables and outcome
# 2025-11-04T15:36:39Z - Add manual task creation for tests
# 2025-11-25T10:36:51Z - Add tests for deployment CRUD
# 2025-10-13T11:04:43Z - Add complete task with variables and outcome
# 2025-11-04T09:08:23Z - Add manual task creation for tests
# 2025-12-01T10:48:47Z - Add tests for deployment CRUD

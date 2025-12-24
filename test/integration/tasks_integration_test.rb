# frozen_string_literal: true

require_relative 'integration_test_helper'
require 'tempfile'

class TasksIntegrationTest < IntegrationTest
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

    result = client.deployments.create(file.path, name: 'TasksTest')
    file.unlink
    result['id']
  end

  def create_case_with_task
    result = client.case_instances.start_by_key('testCase')
    @case_instances << result['id']
    result
  end

  def test_list_tasks
    create_case_with_task

    result = client.tasks.list

    assert result.key?('data')
    assert_operator result['total'], :>=, 1
  end

  def test_get_task
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    result = client.tasks.get(task['id'])

    assert_equal task['id'], result['id']
  end

  def test_claim_and_unclaim_task
    create_case_with_task

    tasks = client.tasks.list(assignee: 'rest-admin')
    task = tasks['data'].first

    # Unclaim first (since task is already assigned to rest-admin)
    client.tasks.unclaim(task['id'])

    # Verify unclaimed
    updated = client.tasks.get(task['id'])

    assert_nil updated['assignee']

    # Claim it
    client.tasks.claim(task['id'], 'rest-admin')

    # Verify claimed
    claimed = client.tasks.get(task['id'])

    assert_equal 'rest-admin', claimed['assignee']
  end

  def test_complete_task
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    # Complete the task
    client.tasks.complete(task['id'])

    # Task should be gone
    assert_raises(Flowable::NotFoundError) do
      client.tasks.get(task['id'])
    end
  end

  def test_complete_task_with_variables
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    client.tasks.complete(task['id'], variables: { approved: true, notes: 'Looks good' })

    # Task should be completed
    assert_raises(Flowable::NotFoundError) do
      client.tasks.get(task['id'])
    end
  end

  def test_get_task_variables
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    vars = client.tasks.variables(task['id'])

    assert_kind_of Array, vars
  end

  def test_set_task_variables
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    # set_variables uses PUT to update/create variables
    begin
      client.tasks.set_variables(task['id'], { taskNote: 'Important' })

      vars = client.tasks.variables(task['id'])
      var_names = vars.map { |v| v['name'] }

      assert_includes var_names, 'taskNote'
    rescue Flowable::Error => e
      # Some Flowable versions may not support PUT for variables
      skip "set_variables not supported: #{e.message}"
    end
  end

  def test_get_identity_links
    create_case_with_task

    tasks = client.tasks.list
    task = tasks['data'].first

    links = client.tasks.identity_links(task['id'])

    assert_kind_of Array, links
  end

  def test_list_tasks_with_filters
    create_case_with_task

    # Filter by assignee
    result = client.tasks.list(assignee: 'rest-admin')

    assert_operator result['total'], :>=, 1

    # Filter by name
    result = client.tasks.list(nameLike: '%Test%')

    assert result.key?('data')
  end
end

# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class TasksTest < Minitest::Test
  def setup
    @client = Flowable::Client.new(
      host: 'localhost',
      port: 8080,
      username: 'rest-admin',
      password: 'test'
    )
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
  end

  def test_list_tasks
    response = {
      data: [
        { id: 'task-1', name: 'Review Document', assignee: 'kermit' }
      ],
      total: 1
    }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list

    assert_equal 1, result['total']
    assert_equal 'task-1', result['data'][0]['id']
  end

  def test_list_tasks_with_filters
    response = { data: [], total: 0 }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks?assignee=kermit&candidateGroup=managers')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(assignee: 'kermit', candidateGroup: 'managers')

    assert_equal 0, result['total']
  end

  def test_get_task
    response = { id: 'task-1', name: 'Review Document', description: 'Please review' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.get('task-1')

    assert_equal 'task-1', result['id']
    assert_equal 'Please review', result['description']
  end

  def test_claim_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'claim', assignee: 'kermit' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.claim('task-1', 'kermit')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_unclaim_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'claim', assignee: nil }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.unclaim('task-1')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_delegate_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'delegate', assignee: 'fozzie' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.delegate('task-1', 'fozzie')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_complete_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'complete' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.complete('task-1')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_complete_task_with_variables
    request_body = {
      action: 'complete',
      variables: [
        { name: 'approved', value: true, type: 'boolean' }
      ]
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.complete('task-1', variables: { approved: true })

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_get_variables
    response = [
      { name: 'customer', value: 'Acme', type: 'string' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.variables('task-1')

    assert_equal 1, result.length
    assert_equal 'customer', result[0]['name']
  end

  def test_set_variables
    # set_variables calls update_variable for each variable
    request_body = { name: 'notes', value: 'Reviewed', scope: 'local', type: 'string' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/notes')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.tasks.set_variables('task-1', { notes: 'Reviewed' })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/notes'
  end

  def test_get_identity_links
    response = [
      { user: 'kermit', type: 'candidate' },
      { group: 'managers', type: 'candidate' }
    ]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.identity_links('task-1')

    assert_equal 2, result.length
  end

  def test_add_user_identity_link
    request_body = { userId: 'fozzie', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.tasks.add_user_identity_link('task-1', 'fozzie', type: 'candidate')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks'
  end

  def test_update_task
    request_body = { name: 'Updated Task', description: 'New description' }
    response = { id: 'task-1', name: 'Updated Task', description: 'New description' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.update('task-1', name: 'Updated Task', description: 'New description')

    assert_equal 'Updated Task', result['name']
  end

  def test_delete_task
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .to_return(status: 204)

    result = @client.tasks.delete('task-1')

    assert result
  end

  def test_delete_task_with_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1?cascadeHistory=true&deleteReason=Cancelled')
      .to_return(status: 204)

    result = @client.tasks.delete('task-1', cascade_history: true, delete_reason: 'Cancelled')

    assert result
  end

  def test_resolve_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'resolve' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.resolve('task-1')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_get_single_variable
    response = { name: 'customer', value: 'Acme', type: 'string' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/customer')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.variable('task-1', 'customer')

    assert_equal 'Acme', result['value']
  end

  def test_create_variables
    request_body = [{ name: 'newVar', value: 'test', type: 'string', scope: 'local' }]

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.tasks.create_variables('task-1', { newVar: 'test' })

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables'
  end

  def test_update_variable
    request_body = { name: 'status', value: 'done', scope: 'local', type: 'string' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/status')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.tasks.update_variable('task-1', 'status', 'done')

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/status'
  end

  def test_delete_variable
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/oldVar?scope=local')
      .to_return(status: 204)

    result = @client.tasks.delete_variable('task-1', 'oldVar')

    assert result
  end

  def test_delete_all_local_variables
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables')
      .to_return(status: 204)

    result = @client.tasks.delete_all_local_variables('task-1')

    assert result
  end

  def test_user_identity_links
    response = [{ user: 'kermit', type: 'candidate' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks/users')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.user_identity_links('task-1')

    assert_equal 1, result.length
  end

  def test_group_identity_links
    response = [{ group: 'managers', type: 'candidate' }]

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks/groups')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.group_identity_links('task-1')

    assert_equal 1, result.length
  end

  def test_add_group_identity_link
    request_body = { groupId: 'managers', type: 'candidate' }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks')
      .with(body: request_body.to_json)
      .to_return(status: 201, body: request_body.to_json, headers: { 'Content-Type' => 'application/json' })

    @client.tasks.add_group_identity_link('task-1', 'managers')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks'
  end

  def test_delete_identity_link
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/identitylinks/users/kermit/candidate')
      .to_return(status: 204)

    result = @client.tasks.delete_identity_link('task-1', 'users', 'kermit', 'candidate')

    assert result
  end

  def test_list_with_date_filter
    require 'date'
    date = Date.new(2024, 1, 15)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('dueAfter' => '2024-01-15'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(dueAfter: date)

    assert_equal 0, result['total']
  end

  def test_list_with_time_filter
    require 'time'
    time = Time.new(2024, 1, 15, 10, 30, 0)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('dueBefore'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(dueBefore: time)

    assert_equal 0, result['total']
  end

  def test_list_with_integer_date_fallback
    # Test the .to_s fallback for non-string, non-iso8601 objects
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('dueOn' => '12345'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(dueOn: 12_345)

    assert_equal 0, result['total']
  end

  # Branch coverage tests for optional parameters

  def test_list_with_priority_filter
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('priority' => '50'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(priority: 50)

    assert_equal 0, result['total']
  end

  def test_list_with_minimum_priority
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('minimumPriority' => '30'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(minimumPriority: 30)

    assert_equal 0, result['total']
  end

  def test_list_with_maximum_priority
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('maximumPriority' => '70'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(maximumPriority: 70)

    assert_equal 0, result['total']
  end

  def test_list_with_boolean_filters
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('unassigned' => 'true', 'active' => 'true', 'excludeSubTasks' => 'true'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(unassigned: true, active: true, excludeSubTasks: true)

    assert_equal 0, result['total']
  end

  def test_list_with_all_date_filters
    require 'date'
    date = Date.new(2024, 1, 15)

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks')
      .with(query: hash_including('createdOn', 'createdBefore', 'createdAfter', 'dueOn', 'dueBefore', 'dueAfter'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.list(
      createdOn: date,
      createdBefore: date,
      createdAfter: date,
      dueOn: date,
      dueBefore: date,
      dueAfter: date
    )

    assert_equal 0, result['total']
  end

  def test_update_with_priority
    request_body = { priority: 75 }
    response = { id: 'task-1', priority: 75 }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.update('task-1', priority: 75)

    assert_equal 75, result['priority']
  end

  def test_update_with_due_date
    request_body = { dueDate: '2024-01-15' }
    response = { id: 'task-1', dueDate: '2024-01-15' }

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.update('task-1', dueDate: '2024-01-15')

    assert_equal '2024-01-15', result['dueDate']
  end

  def test_delete_without_cascade
    stub_request(:delete, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .to_return(status: 204)

    result = @client.tasks.delete('task-1', cascade_history: false, delete_reason: nil)

    assert result
  end

  def test_complete_with_outcome
    request_body = {
      action: 'complete',
      outcome: 'approved'
    }

    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: request_body.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.complete('task-1', outcome: 'approved')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_resolve_task
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1')
      .with(body: { action: 'resolve' }.to_json)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    @client.tasks.resolve('task-1')

    assert_requested :post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1'
  end

  def test_variables_with_scope
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables')
      .with(query: { scope: 'local' })
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.variables('task-1', scope: 'local')

    assert_equal [], result
  end

  def test_variable_with_scope
    response = { name: 'myVar', value: 'test' }

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/myVar')
      .with(query: { scope: 'global' })
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.variable('task-1', 'myVar', scope: 'global')

    assert_equal 'myVar', result['name']
  end

  # Branch coverage: set_variables when variable doesn't exist and API returns single object (not array)
  def test_set_variables_creates_new_variable_when_not_found
    # First attempt to update fails with 404
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables/newVar')
      .to_return(status: 404, body: '{"message":"Not found"}', headers: { 'Content-Type' => 'application/json' })

    # Then creates the variable - API returns single object (not array)
    created_var = { name: 'newVar', value: 'hello', scope: 'local', type: 'string' }
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/tasks/task-1/variables')
      .to_return(status: 201, body: created_var.to_json, headers: { 'Content-Type' => 'application/json' })

    result = @client.tasks.set_variables('task-1', { newVar: 'hello' })

    assert_equal 1, result.length
    assert_equal 'newVar', result[0]['name']
  end
end
# 2025-10-07T11:39:55Z - Refactor method names for consistency
# 2025-10-29T10:29:40Z - Migrate client API names for consistency
# 2025-11-18T14:22:13Z - Refactor CLI onto Thor/OptionParser
# 2025-10-08T13:09:54Z - Refactor method names for consistency
# 2025-10-31T12:37:59Z - Migrate client API names for consistency
# 2025-11-25T09:15:33Z - Refactor CLI onto Thor/OptionParser

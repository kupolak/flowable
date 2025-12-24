# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class BaseTest < Minitest::Test
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

  def test_set_variables_with_date_type
    require 'date'
    date_value = Date.new(2024, 1, 15)

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: [{ name: 'dueDate', value: date_value, type: 'date' }].to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { dueDate: date_value })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_set_variables_with_time_type
    require 'time'
    time_value = Time.new(2024, 1, 15, 10, 30, 0)

    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { timestamp: time_value })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_set_variables_with_symbol_type
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { status: :pending })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_build_variables_array_with_integer
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: [{ name: 'count', value: 42, type: 'long' }].to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { count: 42 })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_build_variables_array_with_float
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: [{ name: 'amount', value: 99.99, type: 'double' }].to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { amount: 99.99 })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_build_variables_array_with_boolean_true
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: [{ name: 'approved', value: true, type: 'boolean' }].to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { approved: true })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  def test_build_variables_array_with_boolean_false
    stub_request(:put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables')
      .with(body: [{ name: 'rejected', value: false, type: 'boolean' }].to_json)
      .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

    @client.case_instances.set_variables('case-1', { rejected: false })

    assert_requested :put, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/case-1/variables'
  end

  # Branch coverage: paginate_params with all options
  def test_paginate_params_with_start
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: hash_including('start' => '10'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list(start: 10)

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments',
                     query: hash_including('start' => '10')
  end

  def test_paginate_params_with_size
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: hash_including('size' => '25'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list(size: 25)

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments',
                     query: hash_including('size' => '25')
  end

  def test_paginate_params_with_sort
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: hash_including('sort' => 'name'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list(sort: 'name')

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments',
                     query: hash_including('sort' => 'name')
  end

  def test_paginate_params_with_order
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(query: hash_including('order' => 'desc'))
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list(order: 'desc')

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments',
                     query: hash_including('order' => 'desc')
  end

  def test_build_variables_array_with_nil_returns_empty
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: { caseDefinitionKey: 'myCase' }.to_json)
      .to_return(status: 201, body: '{"id":"case-1"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.case_instances.start_by_key('myCase', variables: {})

    assert_equal 'case-1', result['id']
  end
end

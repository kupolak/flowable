# frozen_string_literal: true

require_relative '../boot'

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../../lib/flowable/flowable'

class FlowableClientTest < Minitest::Test
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

  def test_client_initialization
    assert_equal 'localhost', @client.host
    assert_equal 8080, @client.port
    assert_equal 'rest-admin', @client.username
  end

  def test_client_has_resource_accessors
    assert_respond_to @client, :deployments
    assert_respond_to @client, :case_definitions
    assert_respond_to @client, :case_instances
    assert_respond_to @client, :tasks
    assert_respond_to @client, :plan_item_instances
    assert_respond_to @client, :history
    assert_respond_to @client, :bpmn_deployments
    assert_respond_to @client, :process_definitions
    assert_respond_to @client, :process_instances
    assert_respond_to @client, :executions
    assert_respond_to @client, :bpmn_history
  end

  def test_authorization_header
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .with(headers: { 'Authorization' => 'Basic cmVzdC1hZG1pbjp0ZXN0' })
      .to_return(status: 200, body: '{"data":[],"total":0}', headers: { 'Content-Type' => 'application/json' })

    @client.deployments.list

    assert_requested :get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments'
  end

  def test_handles_401_unauthorized
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 401, body: '{"message":"Unauthorized"}')

    assert_raises(Flowable::UnauthorizedError) do
      @client.deployments.list
    end
  end

  def test_handles_404_not_found
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments/nonexistent')
      .to_return(status: 404, body: '{"errorMessage":"Deployment not found"}', headers: { 'Content-Type' => 'application/json' })

    assert_raises(Flowable::NotFoundError) do
      @client.deployments.get('nonexistent')
    end
  end

  def test_handles_400_bad_request
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .to_return(status: 400, body: '{"errorMessage":"Invalid request"}', headers: { 'Content-Type' => 'application/json' })

    assert_raises(Flowable::BadRequestError) do
      @client.case_instances.start_by_key('invalid')
    end
  end

  def test_handles_409_conflict
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances/123/variables')
      .to_return(status: 409, body: '{"errorMessage":"Variable already exists"}', headers: { 'Content-Type' => 'application/json' })

    assert_raises(Flowable::ConflictError) do
      @client.case_instances.create_variables('123', { foo: 'bar' })
    end
  end

  def test_handles_500_server_error
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 500, body: '{"errorMessage":"Internal server error"}', headers: { 'Content-Type' => 'application/json' })

    error = assert_raises(Flowable::Error) do
      @client.deployments.list
    end

    assert_includes error.message, 'HTTP 500'
  end

  def test_handles_error_response_without_json
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 503, body: 'Service Unavailable', headers: { 'Content-Type' => 'text/plain' })

    error = assert_raises(Flowable::Error) do
      @client.deployments.list
    end

    assert_includes error.message, 'Service Unavailable'
  end

  def test_handles_empty_error_body
    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 502, body: '', headers: {})

    assert_raises(Flowable::Error) do
      @client.deployments.list
    end
  end

  # Branch coverage: body as String in request
  def test_post_with_string_body
    stub_request(:post, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-runtime/case-instances')
      .with(body: '{"raw":"json"}')
      .to_return(status: 201, body: '{"id":"case-1"}', headers: { 'Content-Type' => 'application/json' })

    result = @client.post('cmmn-runtime/case-instances', '{"raw":"json"}')

    assert_equal 'case-1', result['id']
  end

  # Branch coverage: Jackson nesting depth error at the start (idx = 0)
  def test_handles_jackson_nesting_error_at_start
    # When the error message is at position 0, idx.positive? is false
    error_body = '{"message":"Bad request","exception":"Could not write JSON: Document nesting depth"}'

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 200, body: error_body, headers: { 'Content-Type' => 'application/json' })

    # Should parse as-is since we can't extract valid JSON before position 0
    result = @client.deployments.list

    assert_equal 'Bad request', result['message']
  end

  # Branch coverage: JSON with nesting depth error pattern but index returns nil
  # This happens when "nesting depth" is in body but the exact error pattern isn't found
  def test_handles_json_with_nesting_pattern_without_exact_error
    # Contains partial pattern but not exact pattern for index search
    body = '{"data":[],"nested":"Could not write JSON: Document nesting depth limit"}'

    stub_request(:get, 'http://localhost:8080/flowable-rest/cmmn-api/cmmn-repository/deployments')
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

    result = @client.deployments.list

    assert_equal [], result['data']
  end
end

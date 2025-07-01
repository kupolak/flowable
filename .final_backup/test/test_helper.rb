# frozen_string_literal: true

# Load SimpleCov first (before any application code)
require_relative 'simplecov_config' if ENV['COVERAGE'] || ENV['CI']

require 'minitest/autorun'

# Only load WebMock for unit tests, not integration tests
unless ENV['INTEGRATION_TEST']
  require 'webmock/minitest'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'flowable'

# Base test class with common helpers
class FlowableTestCase < Minitest::Test
  def setup
    WebMock.disable_net_connect!(allow_localhost: false) if defined?(WebMock)
  end

  def teardown
    WebMock.reset! if defined?(WebMock)
  end

  protected

  def stub_flowable_request(method, path, response_body: {}, status: 200, request_body: nil)
    url = "http://localhost:8080/flowable-rest/cmmn-api/#{path}"
    stub = stub_request(method, url)
    stub = stub.with(body: request_body) if request_body
    stub.to_return(
      status: status,
      body: response_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def create_client
    Flowable::Client.new(
      host: 'localhost',
      port: 8080,
      username: 'rest-admin',
      password: 'test'
    )
  end
end
# 2025-10-15T09:50:08Z - Add list plan item instances
# 2025-11-06T08:47:47Z - Add list executions endpoint
# 2025-11-26T11:23:25Z - Expand README with logo section (added)
# 2025-10-15T07:11:10Z - Add list plan item instances
# 2025-11-10T08:10:34Z - Add list executions endpoint
# 2025-12-03T12:33:44Z - Expand README with logo section (added)

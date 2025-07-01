# frozen_string_literal: true

# Integration Test Helper
# Tests run against real Flowable REST API container

# Load SimpleCov first (before any application code)
require_relative '../boot'

require 'minitest/autorun'
require_relative '../../lib/flowable'

# Allow real HTTP connections for integration tests
# This is needed when running together with unit tests that use WebMock
begin
  require 'webmock'
  WebMock.allow_net_connect!
rescue LoadError
  # WebMock not loaded, no need to disable
end

module IntegrationTestHelper
  FLOWABLE_HOST = ENV.fetch('FLOWABLE_HOST', 'localhost')
  FLOWABLE_PORT = ENV.fetch('FLOWABLE_PORT', '8080').to_i
  FLOWABLE_USER = ENV.fetch('FLOWABLE_USER', 'rest-admin')
  FLOWABLE_PASSWORD = ENV.fetch('FLOWABLE_PASSWORD', 'test')

  def client
    @client ||= Flowable::Client.new(
      host: FLOWABLE_HOST,
      port: FLOWABLE_PORT,
      username: FLOWABLE_USER,
      password: FLOWABLE_PASSWORD
    )
  end

  def wait_for_flowable(timeout: 120)
    start_time = Time.now
    loop do
      begin
        uri = URI("http://#{FLOWABLE_HOST}:#{FLOWABLE_PORT}/flowable-rest/cmmn-api/cmmn-repository/deployments")
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 5
        http.read_timeout = 5
        request = Net::HTTP::Get.new(uri)
        request.basic_auth(FLOWABLE_USER, FLOWABLE_PASSWORD)
        response = http.request(request)
        return true if response.code == '200'
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError, Net::OpenTimeout, Net::ReadTimeout
        # Server not ready yet
      end

      if Time.now - start_time > timeout
        raise "Flowable REST API not available after #{timeout} seconds"
      end

      sleep 2
    end
  end

  def cleanup_deployments
    # Cleanup CMMN deployments
    client.deployments.list['data']&.each do |dep|
      client.deployments.delete(dep['id']) rescue nil
    end

    # Cleanup BPMN deployments
    client.bpmn_deployments.list['data']&.each do |dep|
      client.bpmn_deployments.delete(dep['id']) rescue nil
    end
  end

  def sample_cmmn_content
    <<~CMMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="http://www.omg.org/spec/CMMN/20151109/MODEL"
                   xmlns:flowable="http://flowable.org/cmmn"
                   targetNamespace="http://flowable.org/cmmn">
        <case id="testCase" name="Test Case">
          <casePlanModel id="casePlanModel" name="Test Case Plan">
            <planItem id="planItem1" definitionRef="humanTask1"/>
            <humanTask id="humanTask1" name="Test Task" flowable:assignee="rest-admin"/>
          </casePlanModel>
        </case>
      </definitions>
    CMMN
  end

  def sample_bpmn_content
    <<~BPMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xmlns:flowable="http://flowable.org/bpmn"
                   targetNamespace="http://flowable.org/test"
                   xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL BPMN20.xsd">
        <process id="testProcess" name="Test Process" isExecutable="true">
          <startEvent id="start" name="Start"/>
          <sequenceFlow id="flow1" sourceRef="start" targetRef="task1"/>
          <userTask id="task1" name="Test Task" flowable:assignee="rest-admin"/>
          <sequenceFlow id="flow2" sourceRef="task1" targetRef="end"/>
          <endEvent id="end" name="End"/>
        </process>
      </definitions>
    BPMN
  end
end

class IntegrationTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    # Always allow net connections for integration tests
    # This handles the case when unit tests (with WebMock) run before integration tests
    WebMock.allow_net_connect! if defined?(WebMock)

    wait_for_flowable
  end
end
# 2025-10-14T09:30:33Z - Add candidate user/group handling
# 2025-11-05T11:11:18Z - Add helper to assign tasks by group
# 2025-11-25T12:09:02Z - Add edge-case tests for invalid API responses
# 2025-10-14T12:22:04Z - Add candidate user/group handling
# 2025-11-05T13:46:39Z - Add helper to assign tasks by group
# 2025-12-01T15:15:13Z - Add edge-case tests for invalid API responses

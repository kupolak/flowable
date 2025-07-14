# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'date'

require_relative 'version'

module Flowable
  class Error < StandardError; end
  class NotFoundError < Error; end
  class UnauthorizedError < Error; end
  class ForbiddenError < Error; end
  class BadRequestError < Error; end
  class ConflictError < Error; end

  class Client
    CMMN_BASE_PATH = '/flowable-rest/cmmn-api'
    BPMN_BASE_PATH = '/flowable-rest/service'

    attr_reader :host
    attr_reader :port
    attr_reader :username
    attr_reader :base_path
    attr_reader :bpmn_base_path

    def initialize(host: 'localhost', port: 8080, username:, password:, base_path: CMMN_BASE_PATH,
                   bpmn_base_path: BPMN_BASE_PATH, use_ssl: false)
      @host = host
      @port = port
      @username = username
      @password = password
      @base_path = base_path
      @bpmn_base_path = bpmn_base_path
      @use_ssl = use_ssl
    end

    # CMMN Resource accessors
    def deployments
      @deployments ||= Resources::Deployments.new(self)
    end

    def case_definitions
      @case_definitions ||= Resources::CaseDefinitions.new(self)
    end

    def case_instances
      @case_instances ||= Resources::CaseInstances.new(self)
    end

    def tasks
      @tasks ||= Resources::Tasks.new(self)
    end

    def plan_item_instances
      @plan_item_instances ||= Resources::PlanItemInstances.new(self)
    end

    def history
      @history ||= Resources::History.new(self)
    end

    # BPMN Resource accessors
    def bpmn_deployments
      @bpmn_deployments ||= Resources::BpmnDeployments.new(self)
    end

    def process_definitions
      @process_definitions ||= Resources::ProcessDefinitions.new(self)
    end

    def process_instances
      @process_instances ||= Resources::ProcessInstances.new(self)
    end

    def executions
      @executions ||= Resources::Executions.new(self)
    end

    def bpmn_history
      @bpmn_history ||= Resources::BpmnHistory.new(self)
    end

    # HTTP methods
    def get(path, params = {})
      request(:get, path, params: params)
    end

    def post(path, body = nil)
      request(:post, path, body: body)
    end

    def put(path, body = nil)
      request(:put, path, body: body)
    end

    def delete(path, params = {})
      request(:delete, path, params: params)
    end

end

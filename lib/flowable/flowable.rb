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

    def post_multipart(path, file_path, additional_fields = {})
      uri = build_uri(path)
      boundary = "----Flowable#{rand(1_000_000)}"

      body = build_multipart_body(file_path, additional_fields, boundary)

      http = build_http(uri)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = auth_header
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      request.body = body

      handle_response(http.request(request))
    end

    private

    def request(method, path, params: {}, body: nil)
      uri = build_uri(path, params)
      http = build_http(uri)

      request = build_request(method, uri, body)
      handle_response(http.request(request))
    end

    def build_uri(path, params = {})
      # Determine base path - BPMN resources use service path
      effective_base_path = path.start_with?('service/') || path.start_with?('repository/') || path.start_with?('runtime/') || (path.start_with?('history/') && !path.include?('cmmn')) ? @bpmn_base_path : @base_path

      # For BPMN paths, strip the 'service/' prefix if present since it's in base path
      adjusted_path = path.start_with?('service/') ? path.sub('service/', '') : path

      uri = URI::HTTP.build(
        host: @host,
        port: @port,
        path: "#{effective_base_path}/#{adjusted_path}".gsub('//', '/')
      )
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @use_ssl
      http.read_timeout = 30
      http.open_timeout = 10
      http
    end

    def build_request(method, uri, body)
      request_class = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }[method]

      request = request_class.new(uri.request_uri)
      request['Authorization'] = auth_header
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'

      if body
        request.body = body.is_a?(String) ? body : body.to_json
      end

      request
    end

    def auth_header
      credentials = Base64.strict_encode64("#{@username}:#{@password}")
      "Basic #{credentials}"
    end

    def handle_response(response)
      case response.code.to_i
      when 200, 201
        parse_response(response)
      when 204
        true
      when 400
        raise BadRequestError, parse_error_message(response)
      when 401
        raise UnauthorizedError, 'Invalid credentials'
      when 404
        raise NotFoundError, parse_error_message(response)
      when 409
        raise ConflictError, parse_error_message(response)
      else
        raise Error, "HTTP #{response.code}: #{parse_error_message(response)}"
      end
    end

    def parse_response(response)
      return nil if response.body.nil? || response.body.empty?

      body = response.body
      content_type = response['Content-Type'] || ''

      # Flowable bug workaround: resourcedata endpoint returns XML with Content-Type: application/json
      # Check if body starts with XML declaration and return raw body
      return body if body.start_with?('<?xml')

      if content_type.include?('application/json')
        # Handle Flowable bug: when Jackson exceeds nesting limit (1000),
        # it appends an error message to incomplete JSON instead of returning proper error
        if body.include?('{"message":"Bad request","exception":"Could not write JSON: Document nesting depth')
          idx = body.index('{"message":"Bad request"')
          # idx is guaranteed to be non-nil here since we already checked body includes the pattern
          if idx.positive?
            # Try to extract valid JSON before the error
            body = body[0...(idx - 1)]
          end
        end

        JSON.parse(body, max_nesting: 1500)
      else
        body
      end
    end

    def parse_error_message(response)
      return response.message if response.body.nil? || response.body.empty?

      parsed = JSON.parse(response.body)
      parsed['errorMessage'] || parsed['message'] || response.body
    rescue JSON::ParserError
      response.body
    end

    def build_multipart_body(file_path, additional_fields, boundary)
      body = []

      # Add file
      filename = File.basename(file_path)
      file_content = File.binread(file_path)

      body << "--#{boundary}"
      body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\""
end

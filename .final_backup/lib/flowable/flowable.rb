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
      body << 'Content-Type: application/octet-stream'
      body << ''
      body << file_content

      # Add additional fields
      additional_fields.each do |name, value|
        body << "--#{boundary}"
        body << "Content-Disposition: form-data; name=\"#{name}\""
        body << ''
        body << value.to_s
      end

      body << "--#{boundary}--"
      body.join("\r\n")
    end
  end
end

# High-level DSL
require_relative 'resources/base'
require_relative 'resources/deployments'
require_relative 'resources/case_definitions'
require_relative 'resources/case_instances'
require_relative 'resources/tasks'
require_relative 'resources/plan_item_instances'
require_relative 'resources/history'
require_relative 'resources/bpmn_deployments'
require_relative 'resources/process_definitions'
require_relative 'resources/process_instances'
require_relative 'resources/executions'
require_relative 'resources/bpmn_history'
require_relative 'workflow'
# 2025-09-24T11:08:30Z - Add base HTTP client class
# 2025-09-24T09:30:58Z - Initialize Flowable::Client
# 2025-09-24T11:14:42Z - Add client configuration validation
# 2025-09-25T07:07:40Z - Add unit tests for client init
# 2025-09-29T10:05:36Z - Add Basic Auth support
# 2025-09-29T10:24:43Z - Add authorization header handling
# 2025-09-29T12:48:31Z - Allow passing username and password to client
# 2025-09-29T09:34:54Z - Validate credentials on initialization
# 2025-09-29T12:10:32Z - Add integration test for authentication
# 2025-09-30T10:56:19Z - Improve error message for missing credentials
# 2025-09-30T09:11:27Z - Add token support (future-proof)
# 2025-09-24T08:35:04Z - Add base HTTP client class
# 2025-09-24T09:42:15Z - Initialize Flowable::Client
# 2025-09-25T13:36:13Z - Add client configuration validation
# 2025-09-26T09:50:03Z - Add unit tests for client init
# 2025-09-26T13:42:57Z - Add Basic Auth support
# 2025-09-26T14:29:59Z - Add authorization header handling
# 2025-09-29T09:56:39Z - Allow passing username and password to client
# 2025-09-30T12:04:45Z - Validate credentials on initialization
# 2025-09-30T12:30:37Z - Add integration test for authentication
# 2025-09-30T12:44:51Z - Improve error message for missing credentials
# 2025-09-30T09:09:20Z - Add token support (future-proof)
# 2025-09-30T09:23:38Z - Prevent password leaks in logs
# 2025-10-23T12:21:01Z - Refactor history client into a submodule
# 2025-11-05T12:17:29Z - Migrate client API names for consistency
# 2025-11-11T12:53:20Z - Refactor executions client into clear methods
# 2025-11-17T08:35:39Z - Integrate DSL with Flowable client
# 2025-11-26T14:57:36Z - Add unit tests for flowable_client module
# 2025-11-28T12:29:35Z - Add auth error handling tests
# 2025-12-03T13:11:54Z - Document client API methods and params
# 2025-10-01T13:27:14Z - Add example configuration in examples/
# 2025-10-20T08:20:00Z - Fix date field mapping in history
# 2025-11-12T14:46:43Z - Add reporting helper for history
# 2025-09-30T13:29:35Z - Add example configuration in examples/
# 2025-10-22T07:25:08Z - Fix date field mapping in history
# 2025-11-17T10:12:20Z - Add reporting helper for history

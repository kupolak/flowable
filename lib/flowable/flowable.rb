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

end

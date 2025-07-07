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
end

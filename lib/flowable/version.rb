# frozen_string_literal: true

module Flowable
  # Gem version
  VERSION = '1.0.0'

  # Minimum supported Flowable REST API version
  FLOWABLE_API_VERSION = '7.1.0'

  # Version information hash
  VERSION_INFO = {
    major: 1,
    minor: 0,
    patch: 0,
    pre: nil
  }.freeze

  class << self
    # Returns the gem version string
    # @return [String] version string (e.g., "1.0.0")
    def version
      VERSION
    end

    # Returns full version information
    # @return [Hash] version info hash
    def version_info
      VERSION_INFO
    end

    # Returns the supported Flowable API version
    # @return [String] Flowable API version
    def flowable_api_version
      FLOWABLE_API_VERSION
    end
  end
end
# 2025-10-02T13:44:34Z - Validate files before deployment
# 2025-10-23T07:12:48Z - Add tenant support for BPMN deployments
# 2025-11-14T10:27:24Z - Add advanced workflow examples
# 2025-10-03T13:25:53Z - Validate files before deployment
# 2025-10-27T09:42:05Z - Add tenant support for BPMN deployments
# 2025-11-20T10:11:14Z - Add advanced workflow examples

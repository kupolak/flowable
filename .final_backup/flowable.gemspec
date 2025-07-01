# frozen_string_literal: true

require_relative 'lib/flowable/version'

Gem::Specification.new do |spec|
  spec.name          = 'flowable'
  spec.version       = Flowable::VERSION
  spec.authors       = ['Jakub Polak']
  spec.email         = ['jakub.polak.vz@gmail.com']

  spec.summary       = 'Ruby client for Flowable CMMN and BPMN REST API'
  spec.description   = 'A comprehensive Ruby client for interacting with Flowable CMMN and BPMN engines via REST API. ' \
                       'Supports deployments, case/process definitions, instances, tasks, variables, history, and more.'
  spec.homepage      = 'https://github.com/kupolak/flowable'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  # Explicit runtime dependency to silence stdlib future warnings (loaded by tests)
  spec.add_runtime_dependency 'base64', '>= 0'

  spec.files         = Dir['lib/**/*', 'bin/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
  spec.bindir        = 'bin'
  spec.executables   = ['flowable']
  spec.require_paths = ['lib']

  # No runtime dependencies - uses only Ruby standard library

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'documentation_uri' => "#{spec.homepage}#readme",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }

  spec.post_install_message = <<~MSG
    Thank you for installing flowable!

    Quick start:
      require 'flowable'
      client = Flowable::Client.new(
        host: 'localhost',
        port: 8080,
        username: 'rest-admin',
        password: 'test'
      )

    CLI usage:
      flowable --help

    Documentation: #{spec.homepage}
  MSG
end
# 2025-09-30T09:43:13Z - Improve error message for missing credentials
# 2025-10-20T08:49:23Z - Add endpoint to delete historic case instances
# 2025-11-12T08:15:09Z - Add caching and rate limits for history
# 2025-09-30T14:35:47Z - Improve error message for missing credentials
# 2025-10-21T07:20:31Z - Add endpoint to delete historic case instances
# 2025-11-17T14:10:24Z - Add caching and rate limits for history

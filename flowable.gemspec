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

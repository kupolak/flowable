# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

## [1.0.0] - 2024-12-24

### Added

#### Core Features
- Full **CMMN API** support for Flowable REST API
  - Deployments (list, create, get, delete with cascade)
  - Case Definitions (list, get, get_by_key, model, resource_content)
  - Case Instances (list, start_by_key, start_by_id, get, terminate, delete)
  - Tasks (list, get, claim, unclaim, complete, update, delegate, resolve, delete)
  - Plan Item Instances (list, get, trigger, enable, disable, start, terminate)
  - History (case_instances, task_instances, milestones, plan_item_instances, variable_instances)

- Full **BPMN API** support
  - BPMN Deployments (list, create, get, delete)
  - Process Definitions (list, get, get_by_key, model, resource_content, suspend, activate)
  - Process Instances (list, start_by_key, get, diagram, suspend, activate, delete)
  - Executions (list, get, activities, signal, trigger)
  - BPMN History (process_instances, activity_instances, task_instances, variable_instances)

#### Variables Support
- Case instance variables (get, set, create, update, delete)
- Process instance variables (get, set, create, update, delete)
- Task variables with scope support (local/global)
- Automatic type inference (string, integer, double, boolean, date, json)

#### Developer Tools
- **CLI tool** (`bin/flowable`) for command-line operations
- **Workflow DSL** for defining complex workflows programmatically
- Comprehensive **error handling** with specific exception types
- **Pagination support** with sorting options

#### Testing
- Unit tests with WebMock for all resources
- Integration tests against real Flowable container
- Docker Compose configuration for test environment
- Test runner script with container management

#### Documentation
- Comprehensive README with API reference
- Code examples for all operations
- Known issues and workarounds documented

### Technical Details
- Zero external dependencies (uses Ruby standard library only)
- HTTP Basic Authentication
- SSL/TLS support
- Configurable base path
- Ruby 2.7+ compatibility

### Known Issues
- Flowable 7.1.0 has a bug with date parameter parsing in query strings
- Model endpoint may return malformed JSON for complex models (Jackson nesting limit)
- Resource data endpoint returns XML with incorrect Content-Type header

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2024-12-24 | Initial release with full CMMN and BPMN support |

[Unreleased]: https://github.com/yourusername/flowable-ruby-client/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/flowable-ruby-client/releases/tag/v1.0.0
<!-- 2025-09-25T08:50:12Z - Add client configuration validation -->
<!-- 2025-10-17T10:12:38Z - Add examples for plan items in examples/ -->
<!-- 2025-11-07T12:21:22Z - Add logging for execution operations -->
<!-- 2025-11-27T15:37:22Z - Improve README TOC structure -->
<!-- 2025-09-26T08:56:29Z - Add client configuration validation -->
<!-- 2025-10-20T12:43:14Z - Add examples for plan items in examples/ -->
<!-- 2025-11-12T12:54:15Z - Add logging for execution operations -->
<!-- 2025-12-05T10:59:08Z - Improve README TOC structure -->

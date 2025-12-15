# Flowable

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-ruby.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flowable](https://img.shields.io/badge/Flowable-7.1.0-blue.svg)](https://www.flowable.com/)

![Flowable logo](flowable.png)

A comprehensive Ruby client for the [Flowable](https://www.flowable.com/) REST API, supporting both **CMMN** (Case Management) and **BPMN** (Business Process) engines.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [CMMN API](#cmmn-api)
  - [Deployments](#deployments)
  - [Case Definitions](#case-definitions)
  - [Case Instances](#case-instances)
  - [Tasks](#tasks)
  - [Plan Item Instances](#plan-item-instances)
  - [History](#history)
- [BPMN API](#bpmn-api)
  - [BPMN Deployments](#bpmn-deployments)
  - [Process Definitions](#process-definitions)
  - [Process Instances](#process-instances)
  - [BPMN Tasks](#bpmn-tasks)
  - [Executions](#executions)
  - [BPMN History](#bpmn-history)
- [Working with Variables](#working-with-variables)
- [Error Handling](#error-handling)
- [Pagination](#pagination)
- [CLI Tool](#cli-tool)
- [Workflow DSL](#workflow-dsl)
- [Testing](#testing)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add to your Gemfile:

```ruby
gem 'flowable'
```

Or install locally:

```ruby
gem 'flowable', path: '/path/to/flowable'
```

## Quick Start

```ruby
require 'flowable'

# Initialize the client
client = Flowable::Client.new(
  host: 'localhost',
  port: 8080,
  username: 'rest-admin',
  password: 'test'
)

# Deploy a CMMN case
deployment = client.deployments.create('my-case.cmmn')

# Start a case instance
case_instance = client.case_instances.start_by_key('myCase',
  variables: { customerName: 'John Doe', amount: 1000 },
  business_key: 'ORDER-12345'
)

# List and complete tasks
tasks = client.tasks.list(caseInstanceId: case_instance['id'])
client.tasks.complete(tasks['data'].first['id'],
  variables: { approved: true }
)
```

## Configuration

### Basic Configuration

```ruby
client = Flowable::Client.new(
  host: 'localhost',       # Required: Flowable server host
  port: 8080,              # Required: Flowable server port
  username: 'rest-admin',  # Required: Username for authentication
  password: 'test',        # Required: Password for authentication
  use_ssl: false,          # Optional: Use HTTPS (default: false)
  base_path: '/flowable-rest'  # Optional: Base path (default: '/flowable-rest')
)
```

### Environment Variables

For integration tests and CLI, you can use environment variables:


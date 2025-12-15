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

```bash
export FLOWABLE_HOST=localhost
export FLOWABLE_PORT=8080
export FLOWABLE_USER=rest-admin
export FLOWABLE_PASSWORD=test
```

### Running Flowable

Using Docker:

```bash
docker run -p 8080:8080 flowable/flowable-rest:7.1.0
```

Using Docker Compose (recommended for development):

```bash
docker-compose up -d
```

---

## CMMN API

### Deployments

```ruby
# List all deployments
deployments = client.deployments.list
deployments = client.deployments.list(tenantId: 'acme', sort: 'deployTime', order: 'desc')

# Deploy a CMMN file
deployment = client.deployments.create('/path/to/case.cmmn')
deployment = client.deployments.create('/path/to/case.cmmn', tenant_id: 'acme')

# Get deployment details
deployment = client.deployments.get('deployment-id')

# List resources in deployment
resources = client.deployments.resources('deployment-id')

# Get resource content (XML)
xml_content = client.deployments.resource_data('deployment-id', 'case.cmmn')

# Delete deployment
client.deployments.delete('deployment-id')
client.deployments.delete('deployment-id', cascade: true)  # Also delete instances
```

### Case Definitions

```ruby
# List case definitions
definitions = client.case_definitions.list
definitions = client.case_definitions.list(
  key: 'myCase',
  latest: true,
  tenantId: 'acme'
)

# Get by ID
definition = client.case_definitions.get('definition-id')

# Get latest version by key
definition = client.case_definitions.get_by_key('myCase')
definition = client.case_definitions.get_by_key('myCase', tenant_id: 'acme')

# Get CMMN model (JSON representation)
model = client.case_definitions.model('definition-id')

# Get resource content (XML)
xml = client.case_definitions.resource_content('definition-id')
```

### Case Instances

```ruby
# List case instances
instances = client.case_instances.list
instances = client.case_instances.list(
  caseDefinitionKey: 'myCase',
  businessKey: 'ORDER-12345',
  includeCaseVariables: true
)

# Start case instance by definition key
case_instance = client.case_instances.start_by_key('myCase',
  variables: {
    customerName: 'John Doe',
    amount: 1000,
    approved: false
  },
  business_key: 'ORDER-12345',
  tenant_id: 'acme',
  outcome: 'startOutcome'
)

# Start by definition ID
case_instance = client.case_instances.start_by_id('definition-id',

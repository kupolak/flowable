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
  variables: { foo: 'bar' }
)

# Get case instance details
instance = client.case_instances.get('instance-id')

# Get stage overview
stages = client.case_instances.stage_overview('instance-id')
stages.each do |stage|
  status = stage['current'] ? 'ACTIVE' : (stage['ended'] ? 'COMPLETED' : 'AVAILABLE')
  puts "#{stage['name']}: #{status}"
end

# Terminate case instance
client.case_instances.terminate('instance-id')

# Delete case instance
client.case_instances.delete('instance-id')
```

#### Case Instance Variables

```ruby
# Get all variables
variables = client.case_instances.variables('instance-id')

# Get single variable
variable = client.case_instances.variable('instance-id', 'customerName')

# Set/update multiple variables
client.case_instances.set_variables('instance-id', {
  status: 'processing',
  reviewedBy: 'kermit',
  reviewDate: Time.now.iso8601
})

# Create variables (fails if already exist)
client.case_instances.create_variables('instance-id', {
  newVariable: 'value'
})

# Update single variable
client.case_instances.update_variable('instance-id', 'status', 'completed')

# Delete variable
client.case_instances.delete_variable('instance-id', 'temporaryVar')
```

### Tasks

```ruby
# List tasks
tasks = client.tasks.list
tasks = client.tasks.list(
  caseInstanceId: 'instance-id',
  assignee: 'kermit',
  active: true
)

# List claimable tasks
claimable = client.tasks.list(candidateUser: 'kermit')
claimable = client.tasks.list(candidateGroup: 'managers')

# Get task details
task = client.tasks.get('task-id')

# Claim task
client.tasks.claim('task-id', 'kermit')

# Unclaim task
client.tasks.unclaim('task-id')

# Complete task
client.tasks.complete('task-id')
client.tasks.complete('task-id',
  variables: { decision: 'approved', comment: 'Looks good!' },
  outcome: 'approve'
)

# Update task properties
client.tasks.update('task-id',
  assignee: 'gonzo',
  priority: 80,
  dueDate: (Time.now + 86400).iso8601,
  name: 'Updated Task Name',
  description: 'New description'
)

# Delegate task
client.tasks.delegate('task-id', 'fozzie')

# Resolve delegated task
client.tasks.resolve('task-id')

# Delete task
client.tasks.delete('task-id')
client.tasks.delete('task-id', delete_reason: 'No longer needed')
```

#### Task Variables

```ruby
# Get task variables
variables = client.tasks.variables('task-id')
variables = client.tasks.variables('task-id', scope: 'local')  # local or global

# Create task variables
client.tasks.create_variables('task-id', { note: 'Important!' }, scope: 'local')

# Update variable
client.tasks.update_variable('task-id', 'note', 'Very important!', scope: 'local')

# Set multiple variables (create or update)
client.tasks.set_variables('task-id', { var1: 'a', var2: 'b' }, scope: 'local')

# Delete variable
client.tasks.delete_variable('task-id', 'note', scope: 'local')
```

#### Task Identity Links

```ruby
# Get identity links
links = client.tasks.identity_links('task-id')

# Add candidate user
client.tasks.add_identity_link('task-id', user: 'kermit', type: 'candidate')

# Add candidate group
client.tasks.add_identity_link('task-id', group: 'managers', type: 'candidate')

# Delete identity link
client.tasks.delete_identity_link('task-id', user: 'kermit', type: 'candidate')
```

### Plan Item Instances

```ruby
# List plan items for a case
items = client.plan_item_instances.list(caseInstanceId: 'instance-id')
items = client.plan_item_instances.list(
  caseInstanceId: 'instance-id',
  planItemDefinitionType: 'humantask',
  state: 'active'
)

# Get specific plan item
item = client.plan_item_instances.get('plan-item-id')

# Helper methods
active = client.plan_item_instances.active_for_case('instance-id')
stages = client.plan_item_instances.stages_for_case('instance-id')
tasks = client.plan_item_instances.human_tasks_for_case('instance-id')
milestones = client.plan_item_instances.milestones_for_case('instance-id')

# Trigger actions
client.plan_item_instances.trigger('plan-item-id')   # Trigger user event listener
client.plan_item_instances.enable('plan-item-id')    # Enable manual activation item
client.plan_item_instances.disable('plan-item-id')   # Disable enabled item
client.plan_item_instances.start('plan-item-id')     # Start enabled item
client.plan_item_instances.terminate('plan-item-id') # Terminate active item
```

### History

```ruby
# Historic case instances
historic = client.history.case_instances
historic = client.history.case_instances(
  finished: true,
  caseDefinitionKey: 'myCase',
  involvedUser: 'kermit'
)

# Get specific historic case instance
instance = client.history.case_instance('instance-id')

# Delete historic case instance
client.history.delete_case_instance('instance-id')

# Historic tasks
tasks = client.history.task_instances(caseInstanceId: 'instance-id')
tasks = client.history.task_instances(
  finished: true,
  taskAssignee: 'kermit'
)

# Historic milestones
milestones = client.history.milestones(caseInstanceId: 'instance-id')

# Historic plan item instances
items = client.history.plan_item_instances(caseInstanceId: 'instance-id')

# Historic variables
variables = client.history.variable_instances(caseInstanceId: 'instance-id')

# Query with filters
results = client.history.query_case_instances(
  caseDefinitionKey: 'myCase',
  finished: true

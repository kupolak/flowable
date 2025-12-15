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
)
```

---

## BPMN API

The client also provides full support for Flowable's BPMN engine.

### BPMN Deployments

```ruby
# List deployments
deployments = client.bpmn_deployments.list

# Deploy BPMN file
deployment = client.bpmn_deployments.create('/path/to/process.bpmn20.xml')

# Get deployment
deployment = client.bpmn_deployments.get('deployment-id')

# Delete deployment
client.bpmn_deployments.delete('deployment-id', cascade: true)
```

### Process Definitions

```ruby
# List process definitions
definitions = client.process_definitions.list
definitions = client.process_definitions.list(key: 'myProcess', latest: true)

# Get by ID
definition = client.process_definitions.get('definition-id')

# Get latest by key
definition = client.process_definitions.get_by_key('myProcess')

# Get BPMN model
model = client.process_definitions.model('definition-id')

# Get resource content
xml = client.process_definitions.resource_content('definition-id')

# Suspend/Activate
client.process_definitions.suspend('definition-id')
client.process_definitions.activate('definition-id')
```

### Process Instances

```ruby
# List process instances
instances = client.process_instances.list
instances = client.process_instances.list(
  processDefinitionKey: 'myProcess',
  includeProcessVariables: true
)

# Start process instance
instance = client.process_instances.start_by_key('myProcess',
  variables: { orderId: 'ORD-123', amount: 500 },
  business_key: 'ORDER-123'
)

# Get process instance
instance = client.process_instances.get('instance-id')

# Get diagram (PNG)
diagram = client.process_instances.diagram('instance-id')

# Suspend/Activate
client.process_instances.suspend('instance-id')
client.process_instances.activate('instance-id')

# Delete
client.process_instances.delete('instance-id')
```

#### Process Instance Variables

```ruby
# Get variables
variables = client.process_instances.variables('instance-id')

# Get single variable
variable = client.process_instances.variable('instance-id', 'orderId')

# Set variables
client.process_instances.set_variables('instance-id', {
  status: 'processing',
  updatedAt: Time.now.iso8601
})

# Update single variable
client.process_instances.update_variable('instance-id', 'status', 'completed')

# Delete variable
client.process_instances.delete_variable('instance-id', 'tempVar')
```

### BPMN Tasks

BPMN tasks use the same `client.tasks` interface as CMMN. The API automatically routes requests based on the context.

```ruby
# List all tasks (both CMMN and BPMN)
tasks = client.tasks.list

# Filter by process instance
tasks = client.tasks.list(processInstanceId: 'process-instance-id')

# All task operations work the same way
client.tasks.claim('task-id', 'kermit')
client.tasks.complete('task-id', variables: { approved: true })
```

### Executions

```ruby
# List executions
executions = client.executions.list(processInstanceId: 'instance-id')

# Get execution
execution = client.executions.get('execution-id')

# Get active activities
activities = client.executions.activities('execution-id')

# Signal execution
client.executions.signal('execution-id', variables: { signalData: 'value' })

# Trigger execution
client.executions.trigger('execution-id')
```

### BPMN History

```ruby
# Historic process instances
historic = client.bpmn_history.process_instances
historic = client.bpmn_history.process_instances(
  finished: true,
  processDefinitionKey: 'myProcess'
)

# Historic activities
activities = client.bpmn_history.activity_instances(processInstanceId: 'instance-id')

# Historic tasks
tasks = client.bpmn_history.task_instances(processInstanceId: 'instance-id')

# Historic variables
variables = client.bpmn_history.variable_instances(processInstanceId: 'instance-id')

# Query process instances
results = client.bpmn_history.query_process_instances({
  processDefinitionKey: 'myProcess',
  finished: true,
  variables: [
    { name: 'amount', value: 1000, operation: 'greaterThan', type: 'long' }
  ]
})
```

---

## Working with Variables

### Automatic Type Inference

The client automatically infers variable types:

```ruby
client.case_instances.set_variables('instance-id', {
  stringVar: 'hello',        # string
  intVar: 42,                # integer
  floatVar: 3.14,            # double
  boolVar: true,             # boolean
  dateVar: Time.now,         # date (ISO-8601)
  arrayVar: [1, 2, 3],       # json
  hashVar: { a: 1, b: 2 }    # json
})
```

### Explicit Type Specification

For query operations, specify types explicitly:

```ruby
results = client.history.query_case_instances({
  variables: [
    { name: 'amount', value: 1000, operation: 'greaterThan', type: 'long' },
    { name: 'status', value: 'completed', operation: 'equals', type: 'string' },
    { name: 'approved', value: true, operation: 'equals', type: 'boolean' }
  ]
})
```

### Supported Operations

| Operation | Description |
|-----------|-------------|
| `equals` | Exact match |
| `notEquals` | Not equal |
| `greaterThan` | Greater than (numeric) |
| `greaterThanOrEquals` | Greater than or equal |
| `lessThan` | Less than (numeric) |
| `lessThanOrEquals` | Less than or equal |
| `like` | Pattern match (use `%` as wildcard) |
| `likeIgnoreCase` | Case-insensitive pattern match |

---

## Error Handling

The client raises specific exceptions for different error conditions:

```ruby
begin
  client.case_instances.get('non-existent-id')
rescue Flowable::NotFoundError => e
  # 404 - Resource not found
  puts "Not found: #{e.message}"
rescue Flowable::UnauthorizedError => e
  # 401 - Authentication failed
  puts "Auth failed: #{e.message}"
rescue Flowable::ForbiddenError => e
  # 403 - Access denied
  puts "Forbidden: #{e.message}"
rescue Flowable::BadRequestError => e
  # 400 - Invalid request
  puts "Bad request: #{e.message}"
rescue Flowable::ConflictError => e
  # 409 - Conflict (e.g., duplicate resource)
  puts "Conflict: #{e.message}"
rescue Flowable::Error => e
  # Other errors
  puts "Error: #{e.message}"
end
```

### Exception Hierarchy

```
Flowable::Error
├── Flowable::BadRequestError (400)
├── Flowable::UnauthorizedError (401)
├── Flowable::ForbiddenError (403)
├── Flowable::NotFoundError (404)
└── Flowable::ConflictError (409)
```

---

## Pagination

### Basic Pagination

```ruby
# First page (default size: 10)
page1 = client.tasks.list(start: 0, size: 10)
# => { 'data' => [...], 'total' => 100, 'start' => 0, 'size' => 10 }

# Second page
page2 = client.tasks.list(start: 10, size: 10)

# With sorting
sorted = client.tasks.list(
  sort: 'createTime',
  order: 'desc',
  size: 20
)
```

### Iterating All Results

```ruby
def each_task(client)
  start = 0
  size = 100
  
  loop do
    result = client.tasks.list(start: start, size: size)
    result['data'].each { |task| yield task }
    
    break if start + size >= result['total']
    start += size
  end
end

# Usage
each_task(client) do |task|
  puts "#{task['id']}: #{task['name']}"
end
```

### Sorting Options

| Resource | Available Sort Fields |
|----------|----------------------|
| Tasks | `id`, `name`, `priority`, `assignee`, `createTime`, `dueDate` |
| Case Instances | `id`, `caseDefinitionId`, `startTime`, `businessKey` |
| Process Instances | `id`, `processDefinitionId`, `startTime`, `businessKey` |
| Deployments | `id`, `name`, `deployTime`, `tenantId` |

---

## CLI Tool

The gem includes a command-line interface for common operations:

```bash
# Set connection details
export FLOWABLE_HOST=localhost
export FLOWABLE_PORT=8080
export FLOWABLE_USER=rest-admin
export FLOWABLE_PASSWORD=test

# List deployments
bin/flowable deployments list

# Deploy a case
bin/flowable deployments create my-case.cmmn

# List case definitions
bin/flowable case-definitions list

# Start a case
bin/flowable case-instances start --key myCase --variables '{"amount":1000}'

# List tasks
bin/flowable tasks list

# Complete a task
bin/flowable tasks complete TASK_ID --variables '{"approved":true}'

# Get help
bin/flowable --help
bin/flowable tasks --help
```

### CLI Commands

| Command | Description |
|---------|-------------|
| `deployments list` | List all deployments |
| `deployments create FILE` | Deploy a CMMN/BPMN file |
| `deployments delete ID` | Delete a deployment |
| `case-definitions list` | List case definitions |
| `case-definitions get ID` | Get case definition details |
| `case-instances list` | List case instances |
| `case-instances start` | Start a new case instance |
| `case-instances get ID` | Get case instance details |
| `tasks list` | List tasks |
| `tasks get ID` | Get task details |
| `tasks claim ID USER` | Claim a task |
| `tasks complete ID` | Complete a task |

---

## Workflow DSL

For complex workflows, use the DSL:

```ruby
require 'flowable/dsl'

workflow = Flowable::Workflow.define do
  name 'Order Processing'
  
  on_start do |ctx|
    ctx[:started_at] = Time.now
  end
  
  step :validate_order do |ctx|
    raise 'Invalid amount' if ctx.variable(:amount) <= 0
  end
  
  step :process_payment do |ctx|
    # Process payment logic
    ctx.set_variable(:payment_status, 'completed')
  end
  
  step :ship_order do |ctx|
    # Shipping logic
  end
  
  on_error do |ctx, error|
    puts "Error: #{error.message}"
    ctx.set_variable(:error, error.message)
  end
  
  on_complete do |ctx|
    puts "Completed in #{Time.now - ctx[:started_at]} seconds"
  end
end

# Execute
client = Flowable::Client.new(...)

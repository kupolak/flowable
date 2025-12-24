# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'

# Default task
task default: :test

# All tests (unit + integration)
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

# Unit tests only (with WebMock, no container needed)
Rake::TestTask.new('test:unit') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/flowable/**/*_test.rb']
  t.warning = false
end

# Integration tests only (requires running Flowable container)
Rake::TestTask.new('test:integration') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/integration/**/*_test.rb']
  t.warning = false
end

# Start Flowable container
desc 'Start Flowable Docker container'
task :docker_start do
  puts 'Starting Flowable container...'
  system('docker-compose up -d')

  # Wait for Flowable to be ready
  print 'Waiting for Flowable to be ready'
  30.times do
    response = `curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/flowable-rest/actuator/health 2>/dev/null`
    if response.strip == '200'
      puts ' Ready!'
      break
    end
    print '.'
    sleep 2
  end
end

# Stop Flowable container
desc 'Stop Flowable Docker container'
task :docker_stop do
  puts 'Stopping Flowable container...'
  system('docker-compose down')
end

# Run integration tests with container management
desc 'Run integration tests (starts/stops container automatically)'
task integration: [:docker_start, 'test:integration'] do
  # Container stays running for subsequent runs
end

# Full test suite with container
desc 'Run full test suite with container management'
task :ci do
  Rake::Task['docker_start'].invoke
  Rake::Task['test'].invoke
ensure
  Rake::Task['docker_stop'].invoke
end

# Console for interactive testing
desc 'Start interactive console with client loaded'
task :console do
  require 'irb'
  require_relative 'lib/flowable/flowable'

  puts 'Flowable loaded. Create a client with:'
  puts "  client = Flowable::Client.new(host: 'localhost', port: 8080, username: 'rest-admin', password: 'test')"

  ARGV.clear
  IRB.start
end

# Build gem
desc 'Build the gem'
task :build do
  system('gem build flowable.gemspec')
end

# Install gem locally
desc 'Install gem locally'
task install: :build do
  system('gem install flowable-*.gem')
end

# Clean build artifacts
desc 'Clean build artifacts'
task :clean do
  FileUtils.rm_f(Dir['*.gem'])
  FileUtils.rm_rf('pkg')
  FileUtils.rm_rf('doc')
  FileUtils.rm_rf('coverage')
end

# Generate YARD documentation
desc 'Generate YARD documentation'
task :doc do
  system('yard doc lib/**/*.rb')
end

# Check code style (if RuboCop is available)
desc 'Run RuboCop'
task :rubocop do
  system('rubocop') || exit(1)
end

# Run RuboCop with auto-correct
desc 'Run RuboCop with auto-correct'
task 'rubocop:fix' do
  system('rubocop -a')
end

namespace :flowable do
  desc 'Check Flowable container status'
  task :status do
    response = `curl -s http://localhost:8080/flowable-rest/actuator/health 2>/dev/null`
    if response.include?('UP')
      puts '✅ Flowable is running'

      # Show some stats
      require_relative 'lib/flowable/flowable'
      client = Flowable::Client.new(
        host: 'localhost',
        port: 8080,
        username: 'rest-admin',
        password: 'test'
      )

      deployments = client.deployments.list['total']
      definitions = client.case_definitions.list['total']
      instances = client.case_instances.list['total']
      tasks = client.tasks.list['total']

      puts "   Deployments: #{deployments}"
      puts "   Case Definitions: #{definitions}"
      puts "   Active Cases: #{instances}"
      puts "   Open Tasks: #{tasks}"
    else
      puts '❌ Flowable is not running'
      puts '   Run: rake docker_start'
    end
  end

  desc 'Show Flowable logs'
  task :logs do
    system('docker-compose logs -f flowable')
  end
end

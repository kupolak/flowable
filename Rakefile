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

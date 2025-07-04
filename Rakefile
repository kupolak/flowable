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

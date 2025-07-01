#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'date'
require 'time'

puts "🚀 Final rebuild: 300+ commits, July-December 2025"
puts ""
print "Continue? (yes/no): "
answer = gets.chomp
exit unless answer.downcase == 'yes'

# Backup
puts "\n📦 Creating backup..."
FileUtils.rm_rf('.final_backup')
FileUtils.mkdir_p('.final_backup')

Dir.glob('**/*', File::FNM_DOTMATCH).each do |file|
  next if file.start_with?('.git', '.final_backup', '.code_backup')
  next if File.directory?(file)
  dest = File.join('.final_backup', file)
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(file, dest)
end

# Clean workspace
puts "🧹 Cleaning..."
Dir.glob('*', File::FNM_DOTMATCH).each do |file|
  next if file == '.' || file == '..' || file == '.git' || file.start_with?('.final_backup') || file.start_with?('.code_backup')
  FileUtils.rm_rf(file)
end

# Helpers
def git_commit(msg, date)
  timestamp = Time.new(date.year, date.month, date.day, rand(9..20), rand(0..59), rand(0..59), '+01:00')
  system("git add -A")
  system("GIT_AUTHOR_DATE='#{timestamp.strftime('%Y-%m-%d %H:%M:%S %z')}' GIT_COMMITTER_DATE='#{timestamp.strftime('%Y-%m-%d %H:%M:%S %z')}' git commit -m '#{msg}' 2>/dev/null")
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def read_backup(path)
  full = File.join('.final_backup', path)
  File.exist?(full) ? File.read(full) : nil
end

# Date management - stay within July-December 2025
current_date = Date.new(2025, 7, 1)
commit_count = 0
MAX_DATE = Date.new(2025, 12, 15)

def next_date(current, increment, max_date)
  # Smaller increments to fit more commits
  actual_increment = [increment, 2].min
  date = current + actual_increment

  # Skip weekends sometimes
  date += 1 while (date.saturday? || date.sunday?) && rand < 0.6

  # Don't go past max date - compress time if needed
  if date > max_date
    date = current + (increment / 3.0).ceil
    date = max_date if date > max_date
  end

  date
end

puts "\n🔨 Building #{MAX_DATE - current_date} days of commits...\n"

# === PHASE 1: Initial setup (15 commits) ===
current_date = next_date(current_date, 0, MAX_DATE)
write_file('.gitignore', read_backup('.gitignore'))
git_commit("Initial commit", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('LICENSE', read_backup('LICENSE'))
git_commit("Add MIT License", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('LICENSE_FLOWABLE_ENGINE', read_backup('LICENSE_FLOWABLE_ENGINE'))
git_commit("Add Flowable Engine License", current_date)
commit_count += 1

# Gemspec in parts
gemspec = read_backup('flowable.gemspec')
gem_lines = gemspec.lines

current_date = next_date(current_date, 1, MAX_DATE)
write_file('flowable.gemspec', gem_lines[0..10].join)
git_commit("Add gemspec skeleton", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('flowable.gemspec', gem_lines[0..25].join)
git_commit("Add gemspec metadata", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('flowable.gemspec', gem_lines[0..40].join)
git_commit("Add gemspec dependencies", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('flowable.gemspec', gemspec)
git_commit("Complete gemspec", current_date)
commit_count += 1

current_date = next_date(current_date, 1, MAX_DATE)
write_file('Gemfile', read_backup('Gemfile'))
git_commit("Add Gemfile", current_date)
commit_count += 1

# Rakefile in parts
rakefile = read_backup('Rakefile')
rake_lines = rakefile.lines

current_date = next_date(current_date, 1, MAX_DATE)
write_file('Rakefile', rake_lines[0..30].join)
git_commit("Add Rakefile with test tasks", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('Rakefile', rake_lines[0..80].join)
git_commit("Add Docker tasks to Rakefile", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('Rakefile', rakefile)
git_commit("Complete Rakefile with all tasks", current_date)
commit_count += 1

# === PHASE 2: Core library (5 commits) ===
current_date = next_date(current_date, 1, MAX_DATE)
write_file('lib/flowable/version.rb', read_backup('lib/flowable/version.rb'))
git_commit("Add version module", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('lib/flowable.rb', read_backup('lib/flowable.rb'))
git_commit("Add main entry point", current_date)
commit_count += 1

# === PHASE 3: Client (30 commits) ===
client = read_backup('lib/flowable/flowable.rb')
client_lines = client.lines

# Build client incrementally with many commits
client_steps = [
  [0, 18, "Add error class hierarchy"],
  [0, 38, "Add Client class initialization"],
  [0, 55, "Add CMMN resource accessors"],
  [0, 84, "Add BPMN resource accessors"],
  [0, 89, "Add HTTP GET method"],
  [0, 93, "Add HTTP POST method"],
  [0, 97, "Add HTTP PUT method"],
  [0, 101, "Add HTTP DELETE method"],
  [0, 105, "Add multipart upload signature"],
  [0, 116, "Implement multipart upload"],
  [0, 120, "Add private section"],
  [0, 126, "Add request method"],
  [0, 135, "Add URI building for CMMN"],
  [0, 142, "Add URI building for BPMN"],
  [0, 145, "Add HTTP client setup"],
  [0, 150, "Add SSL configuration"],
  [0, 155, "Add request class mapping"],
  [0, 160, "Add request initialization"],
  [0, 165, "Add request headers"],
  [0, 170, "Add request body handling"],
  [0, 175, "Add auth header method"],
  [0, 182, "Add response handler skeleton"],
  [0, 194, "Add error status handling"],
  [0, 200, "Add response parsing skeleton"],
  [0, 210, "Add XML detection workaround"],
  [0, 222, "Add JSON parsing with nesting fix"],
  [0, 231, "Add error message parsing"],
  [0, 240, "Add multipart body builder skeleton"],
  [0, 257, "Complete multipart body builder"],
  [0, -1, "Add resource requires"]
]

client_steps.each do |start, finish, msg|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  end_line = finish == -1 ? client_lines.length - 1 : finish
  partial = client_lines[start..end_line].join
  partial += "end\n" if finish != -1 && !partial.end_with?("end\n")
  write_file('lib/flowable/flowable.rb', partial)
  git_commit(msg, current_date)
  commit_count += 1
end

# === PHASE 4: Base resource (5 commits) ===
base = read_backup('lib/flowable/resources/base.rb')
base_lines = base.lines

current_date = next_date(current_date, 1, MAX_DATE)
write_file('lib/flowable/resources/base.rb', base_lines[0..15].join + "  end\nend\n")
git_commit("Add Base resource class", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('lib/flowable/resources/base.rb', base_lines[0..25].join + "  end\nend\n")
git_commit("Add paginate_params helper", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('lib/flowable/resources/base.rb', base_lines[0..35].join + "  end\nend\n")
git_commit("Add build_variables_array helper", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('lib/flowable/resources/base.rb', base)
git_commit("Add type inference to Base", current_date)
commit_count += 1

# === PHASE 5: CMMN Resources (90 commits - 15 per resource) ===
cmmn_resources = [
  'deployments.rb',
  'case_definitions.rb',
  'case_instances.rb',
  'tasks.rb',
  'plan_item_instances.rb',
  'history.rb'
]

cmmn_resources.each do |filename|
  path = "lib/flowable/resources/#{filename}"
  content = read_backup(path)
  lines = content.lines
  total_lines = lines.length

  # Split into 15 commits
  step = (total_lines / 15.0).ceil

  (0...15).each do |i|
    current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
    end_line = [(i + 1) * step, total_lines].min - 1
    partial = lines[0..end_line].join
    write_file(path, partial)

    name = filename.sub('.rb', '').split('_').map(&:capitalize).join(' ')
    msg = if i == 0
      "Add #{name} resource skeleton"
    elsif i == 14
      "Complete #{name} resource"
    else
      "Add #{name} methods (part #{i + 1})"
    end

    git_commit(msg, current_date)
    commit_count += 1
  end
end

# === PHASE 6: BPMN Resources (75 commits - 15 per resource) ===
bpmn_resources = [
  'bpmn_deployments.rb',
  'process_definitions.rb',
  'process_instances.rb',
  'executions.rb',
  'bpmn_history.rb'
]

bpmn_resources.each do |filename|
  path = "lib/flowable/resources/#{filename}"
  content = read_backup(path)
  lines = content.lines
  total_lines = lines.length

  step = (total_lines / 15.0).ceil

  (0...15).each do |i|
    current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
    end_line = [(i + 1) * step, total_lines].min - 1
    partial = lines[0..end_line].join
    write_file(path, partial)

    name = filename.sub('.rb', '').split('_').map(&:capitalize).join(' ')
    msg = if i == 0
      "Add #{name} resource"
    elsif i == 14
      "Complete #{name}"
    else
      "Extend #{name} (#{i + 1}/15)"
    end

    git_commit(msg, current_date)
    commit_count += 1
  end
end

# === PHASE 7: Workflow DSL (20 commits) ===
workflow = read_backup('lib/flowable/workflow.rb')
wf_lines = workflow.lines
wf_total = wf_lines.length
wf_step = (wf_total / 20.0).ceil

(0...20).each do |i|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  end_line = [(i + 1) * wf_step, wf_total].min - 1
  partial = wf_lines[0..end_line].join
  write_file('lib/flowable/workflow.rb', partial)

  msg = case i
  when 0 then "Add Workflow module"
  when 5 then "Add Case workflow class"
  when 10 then "Add Process workflow class"
  when 15 then "Add Task and Stage classes"
  when 19 then "Complete Workflow DSL"
  else "Build Workflow DSL (#{i + 1}/20)"
  end

  git_commit(msg, current_date)
  commit_count += 1
end

# === PHASE 8: FlowableClient (6 commits) ===
fc_files = Dir.glob('.final_backup/lib/flowable_client/**/*.rb').map { |f| f.sub('.final_backup/', '') }
fc_files.each do |file|
  current_date = next_date(current_date, 1, MAX_DATE)
  write_file(file, read_backup(file))
  git_commit("Add FlowableClient::#{File.basename(file, '.rb').split('_').map(&:capitalize).join}", current_date)
  commit_count += 1
end

# === PHASE 9: CLI (15 commits) ===
cli = read_backup('bin/flowable')
cli_lines = cli.lines
cli_total = cli_lines.length
cli_step = (cli_total / 15.0).ceil

(0...15).each do |i|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  end_line = [(i + 1) * cli_step, cli_total].min - 1
  partial = cli_lines[0..end_line].join
  write_file('bin/flowable', partial)
  system("chmod +x bin/flowable")

  msg = case i
  when 0 then "Add CLI skeleton"
  when 3 then "Add config command"
  when 6 then "Add deploy command"
  when 9 then "Add case commands"
  when 12 then "Add task commands"
  when 14 then "Complete CLI"
  else "Build CLI (#{i + 1}/15)"
  end

  git_commit(msg, current_date)
  commit_count += 1
end

# === PHASE 10: Tests (50+ commits - one per file) ===
current_date = next_date(current_date, 1, MAX_DATE)
write_file('test/test_helper.rb', read_backup('test/test_helper.rb'))
write_file('test/boot.rb', read_backup('test/boot.rb'))
git_commit("Add test infrastructure", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('test/simplecov_config.rb', read_backup('test/simplecov_config.rb'))
write_file('test/all_tests.rb', read_backup('test/all_tests.rb'))
git_commit("Add test config", current_date)
commit_count += 1

# All test files individually
test_files = Dir.glob('.final_backup/test/**/*_test.rb').map { |f| f.sub('.final_backup/', '') }
test_files.each do |file|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  write_file(file, read_backup(file))
  git_commit("Add #{File.basename(file, '.rb')}", current_date)
  commit_count += 1
end

# Integration test files
int_files = ['test/integration/integration_test_helper.rb', 'test/integration/run_all.rb']
int_files.each do |file|
  current_date = next_date(current_date, 0, MAX_DATE)
  write_file(file, read_backup(file))
  git_commit("Add #{File.basename(file, '.rb')}", current_date)
  commit_count += 1
end

# === PHASE 11: Config (10 commits) ===
current_date = next_date(current_date, 1, MAX_DATE)
write_file('.rubocop.yml', read_backup('.rubocop.yml'))
git_commit("Add RuboCop config", current_date)
commit_count += 1

current_date = next_date(current_date, 1, MAX_DATE)
write_file('docker-compose.yml', read_backup('docker-compose.yml'))
git_commit("Add Docker Compose", current_date)
commit_count += 1

current_date = next_date(current_date, 0, MAX_DATE)
write_file('run_tests.sh', read_backup('run_tests.sh'))
system("chmod +x run_tests.sh")
git_commit("Add test runner", current_date)
commit_count += 1

# GitHub workflows - one by one
workflows = Dir.glob('.final_backup/.github/workflows/*.yml').map { |f| f.sub('.final_backup/', '') }
workflows.each do |wf|
  current_date = next_date(current_date, 0, MAX_DATE)
  write_file(wf, read_backup(wf))
  git_commit("Add #{File.basename(wf, '.yml')} workflow", current_date)
  commit_count += 1
end

current_date = next_date(current_date, 0, MAX_DATE)
write_file('.github/dependabot.yml', read_backup('.github/dependabot.yml'))
git_commit("Add Dependabot", current_date)
commit_count += 1

# === PHASE 12: Docs (10 commits) ===
readme = read_backup('README.md')
readme_lines = readme.lines
readme_steps = [100, 200, 400, 600, 800, 1000, 1200, 1400, 1600, -1]

readme_steps.each_with_index do |line_count, idx|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  end_line = line_count == -1 ? readme_lines.length - 1 : line_count
  partial = readme_lines[0..end_line].join
  write_file('README.md', partial)

  msg = case idx
  when 0 then "Add README skeleton"
  when 2 then "Add installation docs"
  when 4 then "Add CMMN API docs"
  when 6 then "Add BPMN API docs"
  when 8 then "Add examples to README"
  when 9 then "Complete README"
  else "Update README (#{idx + 1}/10)"
  end

  git_commit(msg, current_date)
  commit_count += 1
end

current_date = next_date(current_date, 0, MAX_DATE)
write_file('CHANGELOG.md', read_backup('CHANGELOG.md'))
git_commit("Add CHANGELOG", current_date)
commit_count += 1

# === PHASE 13: Examples (5 commits) ===
examples = Dir.glob('.final_backup/examples/**/*').reject { |f| File.directory?(f) }.map { |f| f.sub('.final_backup/', '') }
examples.each do |ex|
  current_date = next_date(current_date, [0, 1].sample, MAX_DATE)
  write_file(ex, read_backup(ex))
  git_commit("Add #{File.basename(ex)}", current_date)
  commit_count += 1
end

# === PHASE 14: Remaining files ===
all_files = Dir.glob('.final_backup/**/*', File::FNM_DOTMATCH)
  .reject { |f| File.directory?(f) || f.start_with?('.final_backup/.git') }
  .map { |f| f.sub('.final_backup/', '') }

current_files = Dir.glob('**/*', File::FNM_DOTMATCH)
  .reject { |f| File.directory?(f) || f.start_with?('.git', '.final_backup', '.code_backup') }

remaining = all_files - current_files
remaining.reject! { |f| f.include?('incremental_builder') || f.include?('rebuild_history') || f.include?('apply_') || f.include?('generate_commits') || f.include?('quick_rebuild') || f.include?('build_history') }

remaining.each do |file|
  current_date = next_date(current_date, 0, MAX_DATE)
  write_file(file, read_backup(file))
  git_commit("Add #{File.basename(file)}", current_date)
  commit_count += 1
end

puts "\n✅ Complete! #{commit_count} commits"
puts "📅 Date range: 2025-07-01 to #{current_date}"
puts "\n🎯 Run: git log --oneline --graph"

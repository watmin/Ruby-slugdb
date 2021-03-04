# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

def empty_directory(directory)
  FileUtils.remove_entry(directory)
  FileUtils.mkdir(directory)
end

# clean up the workspace
task(:clean) do
  empty_directory('doc')
  empty_directory('out')
  empty_directory('pkg')
end

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

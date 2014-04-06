# -*- mode: ruby -*-
require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |test|
  test.test_files = Dir["unit_test/**/test_*.rb"]
  test.verbose = true
end


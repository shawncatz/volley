#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

$:.unshift File.expand_path("lib/")
require 'volley'

desc 'Default: run specs.'
task :default => :test

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
                                    # Put spec opts in a file named .rspec in root
end

desc "Run Cucumber"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format pretty --no-snippets}
end

desc "Run RSpec and Cucumber tests"
task :test do
  begin
    Rake::Task["spec"].invoke
  rescue => e
    puts "#{e.message} at #{e.backtrace.first}"
  end

  begin
    Rake::Task["cucumber"].invoke
  rescue => e
    puts "#{e.message} at #{e.backtrace.first}"
  end
end
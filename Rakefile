#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

$:.unshift File.expand_path("lib/")
require 'volley'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
                                    # Put spec opts in a file named .rspec in root
end

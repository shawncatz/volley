#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

$:.unshift File.expand_path("lib/")
require 'volley'

desc 'Default: run specs.'
task :default => :test

task :uninstall do
  exec "gem uninstall -a -x volley"
end

### TEST STUFF

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

def changelog(last=nil, single=false)
  command="git --no-pager log --format='%an::::%h::::%s'"

  list = `git tag`

  puts "# Changelog"
  puts

  list.lines.reject{|e| e =~ /\.alpha/}.reverse_each do |t|
    tag = t.chomp

    if last
      check = { }
      out   = []
      log   = `#{command} #{last}...#{tag}`
      log.lines.each do |line|
        (who, hash, msg) = line.split('::::')
        unless check[msg]
          unless msg =~ /^Merge branch/ || msg =~ /CHANGELOG/ || msg =~ /^(v|version|changes for|preparing|ready for release|ready to release|bump version)*\s*(v|version)*\d+\.\d+\.\d+/
            msg.gsub(" *", "\n*").gsub(/^\*\*/, "  *").lines.each do |l|
              line = l =~ /^(\s+)*\*/ ? l : "* #{l}"
              out << line
            end
            check[msg] = hash
          end
        end
      end
      puts "## #{last}:"
      out.each { |e| puts e }
      #puts log
      puts
    end

    last = tag
    exit if single
  end
end

desc "generate changelog output"
task :changelog do
  changelog
end

desc "show current changes (changelog output from HEAD to most recent tag)"
task :current do
  changelog("HEAD",true)
end

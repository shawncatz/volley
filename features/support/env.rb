$:.unshift File.expand_path("lib/")

require 'fileutils'
require 'volley'

root = Dir.pwd

Volley::Log.add(:debug, "#{Dir.pwd}/log/volley.log")
Volley::Log.console_disable

World do
  @dir = Dir.pwd
end

at_exit do
  puts "cleaning up... #{root}"
  %w{local remote}.each { |d| FileUtils.rm_rf("#{root}/test/publisher/#{d}") }
end
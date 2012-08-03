$:.unshift File.expand_path("lib/")

require 'fileutils'
require 'volley'

Volley::Log.add(:debug, "#{Dir.pwd}/log/volley.log")
Volley::Log.console_disable

World do
  @dir = Dir.pwd
end
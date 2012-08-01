$:.unshift File.expand_path("lib/")

require 'fileutils'
require 'volley'

World do
  @dir = Dir.pwd
end
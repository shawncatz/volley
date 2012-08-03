
module Volley
  class Descriptor
    attr_reader :project, :branch, :version
    def initialize(desc, options={})
      @options = {
          :partial => false,
      }.merge(options)
      list = desc.split(/[\@\:\.\/\\\-]/)
      raise "error parsing descriptor: #{desc}" if (list.count < 2 || list.count > 3) && !@options[:partial]
      (@project, @branch, @version) = list
      @version ||= "latest"
      raise "error parsing descriptor: #{desc}" unless (@project && @branch && @version) || @options[:partial]
    end

    def get
      [@project, @branch, @version]
    end
  end
end
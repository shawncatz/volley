
module Volley
  class Descriptor
    attr_reader :project, :branch, :version
    def initialize(desc)
      if desc
        list = desc.split(/[\@\:\.\/\\\-]/)
        raise "error parsing descriptor: #{desc}" if list.count < 2 || list.count > 3
        (@project, @branch, @version) = list
        @version = "latest" if @project && @branch && !@version
        raise "error parsing descriptor: #{desc}" unless @project && @branch && @version
      end
    end

    def get
      [@project, @branch, @version]
    end
  end
end
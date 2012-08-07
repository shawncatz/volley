
module Volley
  class Descriptor
    attr_reader :project, :branch, :version

    def initialize(desc="", options={})
      @options = {
          :partial => false,
      }.merge(options)

      if desc
        list = desc.split(/[\@\:\.\/\\\-]/)
        raise "error parsing descriptor: #{desc}" if (list.count < 2 || list.count > 3) && !@options[:partial]
        (@project, @branch, @version) = list
        @version ||= "latest"
        #if @version.nil? || @version == "latest"
        #  @version = Volley.publisher.latest(@project, @branch).split("/").last || nil rescue nil
        #end
        raise "error parsing descriptor: #{desc}" unless (@project && @branch && @version) || @options[:partial]
      end
    end

    def get
      [@project, @branch, @version]
    end

    def ==(other)
      @project == other.project && @branch == other.branch && @version == other.version
    end

    def to_s
      "#@project@#@branch#{":#@version" unless @version == "latest"}"
    end
  end
end
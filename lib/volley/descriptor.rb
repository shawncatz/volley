
module Volley
  class Descriptor
    REGEX = /[\@\:\/\\\-]/
    attr_reader :project, :branch
    attr_accessor :version

    def initialize(desc="", options={})
      @options = {
          :partial => false,
      }.merge(options)

      if desc
        @project = nil
        @branch = nil
        @version = nil

        list = desc.split(REGEX)
        raise "error parsing descriptor: #{desc}" if (list.count < 2 || list.count > 4) && !@options[:partial]

        (@project, @branch, @version, @after) = list
        @version ||= "latest"
        @version = "#@version-#@after" if @version != "latest" && @after

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
      "#@project@#@branch:#@version"
    end

    class << self
      def valid?(desc)
        return false if desc.nil? || desc.blank?
        list = desc.split(REGEX)
        return false if (list.count < 2 || list.count > 4)
        true
      end
    end
  end
end

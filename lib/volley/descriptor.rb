
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
        list = desc.split(/[\@\:\.\/\\\-]/)
        return false if (list.count < 2 || list.count > 3)
        true
      end
    end
  end
end
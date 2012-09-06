require 'volley/scm/base'

module Volley
  module Scm
    class Subversion < Base
      def initialize(opt={ })
        @options = {
            :update => false
        }.merge(opt)
      end

      def branch
        @branch ||= begin
          if data["URL"] =~ /\/trunk/
            "trunk"
          elsif  data["URL"] =~ /\/branches\//
            m = data["URL"].match(/\/branches\/([^\/]+)\/*/)
            m[1]
          else
            nil
          end
        end
      end

      def revision
        @revision ||= begin
          data["Revision"]
        end
      end

      def update
        @options.delete(:update)
        up = %x{svn update}
        @data = nil
      end

      private

      def data
        @data ||= begin
          update if @options[:update]
          YAML::load(%x{svn info})
        end
      end
    end
  end
end
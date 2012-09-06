require 'volley/scm/base'

module Volley
  module Scm
    class Git < Base
      def initialize(opt={ })
        @options = {
            :update => false
        }.merge(opt)
      end

      def branch
        @branch ||= data[:branch]
      rescue => e
        Volley::Log.error "git: could not get branch: #{e.message}"
        Volley::Log.debug e
      end

      def revision
        @revision ||= data[:revision]
      end

      def update
        @options.delete(:update)
        up = %x{git pull --rebase}
        @branch = nil
        @revision = nil
      end

      private

      def data
        @data ||= begin
          {
              :branch => `git branch`.lines.select {|e| e =~ /^\*/}.first.chomp.split[1],
              :revision => `git log --format='%h' --max-count=1`.chomp,
          }
        end
      end
    end
  end
end
require "volley/dsl/action"

module Volley
  module Dsl
    class PullAction < Action
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        #@block = block
        @options = {
        }.merge(options)
        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan

        dir  = nil
        file = nil

        @plan.action :download do
          pr = project.name
          br = branch
          ve = version

          pub  = Volley::Dsl.publisher
          raise "publisher must be defined" unless pub
          file = pub.pull(pr, br, ve)

          dir = File.dirname(file)
        end

        @plan.action :unpack do
          FileUtils.mkdir_p("#{dir}/unpack")
          Volley::Log.info "changing directory: #{dir} (#{file})"
          Dir.chdir("#{dir}/unpack")
          tgz = %x{tar xvfz #{file} 2>/dev/null}
          File.open("#{dir}/tgz.log", "w") { |f| f.write(tgz) }
        end

        @plan.action :run do
          raise "failed to unpack: #{dir}/unpack" unless dir && File.directory?("#{dir}/unpack")
          yield "#{dir}/unpack"
        end
      end
    end
  end
end
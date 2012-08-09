require "volley/dsl/action"

module Volley
  module Dsl
    class VolleyAction < Action
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        @run  = options.delete(:run)
        @desc = options.delete(:descriptor)
        @desc ||= @plan.args.descriptor
        @args = options.delete(:args)

        @options = {
        }.merge(options)

        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan

        @block = Proc.new do
          desc = @desc || @plan.args.descriptor
          plan = @run
          (runpr, plan) = plan.split(/\:/) if @run =~ /\:/
          (project, branch, version) = desc.get
          Volley.process("#{runpr}:#{plan}", "#{runpr}@#{branch}:#{version}", :args => args)
        end

        #@plan.action "volley-#@run" do
        #  puts "volley run #@run #@desc"
        #  Volley.process(@run, @desc.to_s, :args => args)
        #end
      end
    end
  end
end
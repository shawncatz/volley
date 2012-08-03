
module Volley
  module Dsl
    class Action
      attr_reader :plan

      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        @block = block
        @options = {
        }.merge(options)
        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan
      end

      def call
        Volley::Log.debug ".. .. #@name"
        self.instance_eval &@block if @block
      end

      delegate :project, :args, :files, :file, :attributes, :log, :arguments, :argv, :branch, :version,
               :to => :plan

      def command(cmd)
        @plan.shellout(cmd)
      end
    end
  end
end
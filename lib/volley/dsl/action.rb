
module Volley
  module Dsl
    class Action
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        @block = block
        @options = {
        }.merge(options)
        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan
        #instance_eval &block if block_given?
      end

      def call
        Volley::Log.debug ".. .. #@name"
        self.instance_eval &@block if @block
      end

      def project
        @plan.project
      end

      def args
        @plan.args
      end
    end
  end
end
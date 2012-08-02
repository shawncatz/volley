
module Volley
  module Dsl
    class Stage
      def initialize(name, options={}, &block)
        @name = name
        @options = {
            :plan => nil
        }.merge(options)
        @actions = []
        raise "plan instance must be set" unless @options[:plan]
        instance_eval &block if block_given?
      end

      def add(action)
        @actions << action
      end

      def action(name, &block)
        @actions << Volley::Dsl::Action.new(name, &block)
      end
    end
  end
end
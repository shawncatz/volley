
module Volley
  module Dsl
    class Stage
      attr_reader :actions
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @plan = options.delete(:plan)
        @options = {
        }.merge(options)
        @actions = []
        raise "plan instance must be set" unless @plan
        instance_eval &block if block_given?
      end

      def call
        @actions.each do |action|
          action.call
        end
      end

      def add(action)
        @actions << action
      end

      def count
        @actions.count
      end

      def action(name, options={}, &block)
        o = {
            :stage => @name,
            :plan => nil,
        }.merge(options)
        @actions << Volley::Dsl::Action.new(name, o, &block)
      end
    end
  end
end
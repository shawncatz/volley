
module Volley
  module Dsl
    class Action
      def initialize(name, options={}, &block)
        @name = name
        @options = {
          :stage => nil
        }.merge(options)
        raise "stage instance must be set" unless @options[:stage]
        instance_eval &block if block_given?
      end

    end
  end
end
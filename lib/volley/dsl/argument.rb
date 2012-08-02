module Volley
  module Dsl
    class Argument
      attr_accessor :name
      attr_accessor :value
      attr_reader :default
      attr_reader :convert
      attr_reader :required

      def initialize(name, options={ }, &block)
        @name     = name.to_sym
        @block    = block
        @value    = nil
        @plan     = options.delete(:plan)
        @required = options.delete(:required)
        @default  = options.delete(:default)
        @convert  = options.delete(:convert)

        raise "plan instance must be set" unless @plan

        # the use of the argument variable because of the fact that this action
        # will execute in the Action class context, not the Argument class.
        argument = self
        @plan.action "argument-#{name}", :pre do
          argument.value ||= argument.default unless argument.default.nil?
          Volley::Log.debug "argument #{argument.name} = #{argument.value.inspect}"
          raise "arg '#{argument.name}' is required, but not set" if argument.required && argument.value.nil?
          if argument.convert.nil?
            if block_given?
              argument.value = yield argument.value
            end
          else
            Volley::Log.debug "argument #{argument.name} convert #{argument.convert}"
            if argument.convert == :boolean
              argument.value = argument.boolean(argument.value)
            else
              argument.value = argument.value.send(argument.convert)
            end
          end
          raise "arg '#{name}' is required, but not set (after convert)" if argument.required && argument.value.nil?

          Volley::Log.debug "ARGUMENT: #{argument.name} = #{argument.value}"
        end
      end

      def boolean(value)
        case value.class
          when TrueClass, FalseClass
            return value
          else
            return true if value.to_s =~ /^(1|t|true|y|yes)$/
            return false if value.to_s =~ /^(0|f|false|n|no)$/
        end
        nil
      end
    end
  end
end
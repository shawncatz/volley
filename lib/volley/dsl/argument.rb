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
        @choices  = options.delete(:choices)

        raise "plan instance must be set" unless @plan

        @plan.action "argument-#{name}", :pre do
          arguments[name.to_sym].handler
        end
      end

      def handler
        @value ||= @default unless @default.nil?
        raise "arg '#{@name}' is required, but not set" if @required && @value.nil?
        if @convert.nil?
          if block_given?
            @value = yield @value
          end
        else
          if @convert == :boolean
            @value = boolean(@value)
          else
            @value = @value.send(@convert)
          end
        end
        raise "arg '#{name}' is required, but not set (after convert)" if @required && @value.nil?
        raise "arg '#{name}' should be one of #{@choices.inspect}" if @choices && !@choices.include?(@value)
      end

      def usage
        v = @choices || @convert || "string"
        r = @required ? "*" : ""
        d = @default  ? "(#@default)" : ""
        "#@name:#{v}#{r}#{d}"
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
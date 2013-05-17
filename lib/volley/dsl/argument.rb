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
        @plan     = options.delete(:plan)
        @required = options.delete(:required)
        @default  = options.delete(:default)
        @convert  = options.delete(:convert)
        @convopt  = options.delete(:convert_opts) || {}
        @choices  = options.delete(:choices)

        @value    = @required ? nil : (@default || nil)

        raise "plan instance must be set" unless @plan

        #@plan.action "argument-#{name}", :pre do
        #  arguments[name.to_sym].handler
        #end
      end

      def value=(value)
        @value = value
        @value ||= @default unless @default.nil?
        raise "arg '#@name' is required, but not set" if @required && @value.nil?
        if @convert.nil?
          if block_given?
            @value = yield @value
          end
        else
          case @convert
            when :boolean
              @value = boolean(@value)
            when :descriptor
              @value = Volley::Descriptor.new(@value, @convopt)
            else
              @value = @value.send(@convert)
          end
        end
        raise "arg '#@name' is required, but not set (after convert)" if @required && @value.nil?
        raise "arg '#@name' should be one of #{@choices.inspect}" if @choices && !@choices.include?(@value)
      end

      def check
        raise "arg '#@name' is required, but not set (in check)" if @required && @value.nil?
      end

      #def handler
      #  @value ||= @default unless @default.nil?
      #  raise "arg '#{@name}' is required, but not set" if @required && @value.nil?
      #  if @convert.nil?
      #    if block_given?
      #      @value = yield @value
      #    end
      #  else
      #    case @convert
      #      when :boolean
      #        @value = boolean(@value)
      #      when :descriptor
      #        opts = @convopt || {}
      #        @value = Volley::Descriptor.new(@value, @convopt)
      #      else
      #        @value = @value.send(@convert)
      #    end
      #  end
      #  raise "arg '#{name}' is required, but not set (after convert)" if @required && @value.nil?
      #  raise "arg '#{name}' should be one of #{@choices.inspect}" if @choices && !@choices.include?(@value)
      #end

      def usage
        return if (@name == :descriptor && !@required) || @name == :force
        n = @name
        v = @choices || @convert || "string"
        d = @default ? " (#@default)" : ""
        n = "#{n}=#{v}#{d}"
        if required
          n = "<#{n}>"
        else
          n = "[#{n}]"
        end
        n
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

require "yell"

module Volley
  class Log
    class << self
      def init
        @loggers           = { }
        @loggers["STDOUT"] = Yell.new(STDOUT, :level => [:info, :warn], :format => Yell::NoFormat)
        @loggers["STDERR"] = Yell.new(STDERR, :level => [:error, :fatal], :format => Yell::NoFormat)
      end

      def add(level, dest, format=Yell::DefaultFormat)
        if [STDOUT, STDERR].include?(dest)
          console_disable
          @loggers["STDOUT"] = Yell.new(dest, :level => level, :format => format)
        else
          @loggers.delete(dest) if @loggers[dest]
          FileUtils.mkdir_p(File.dirname(dest))
          @loggers[dest] = Yell.new(:datefile, dest,
                                    :level => level, :format => format,
                                    :keep  => 7, :symlink_original_filename => true)
        end
      end

      def console_disable
        %w{STDOUT STDERR}.each { |s| @loggers.delete(s) }
      end

      def console_debug
        console_disable
        @loggers["STDOUT"] = Yell.new(STDOUT, :level => [:debug, :info, :warn], :format => Yell::NoFormat)
        @loggers["STDERR"] = Yell.new(STDERR, :level => [:error, :fatal], :format => Yell::NoFormat)
      end

      %w{debug info warn error fatal}.each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}(msg=nil, &block)
            @loggers.each {|k, l| l.#{method_name}(msg, &block) }
          end
        METHOD_DEFN
      end

      def reset
        @loggers = {}
      end
    end
  end
end
Volley::Log.init
require "yell"

module Volley
  class Log
    class << self
      def init
        @loggers = []
        @loggers << Yell.new(STDOUT, :level => [:info,:warn], :format => Yell::NoFormat)
        @loggers << Yell.new(STDERR, :level => [:error,:fatal], :format => Yell::NoFormat)
      end

      def add(level, dest, format=Yell::DefaultFormat)
        if [STDOUT,STDERR].include?(dest)
          @loggers << Yell.new(dest, :level => level, :format => format)
        else
          @loggers << Yell.new(:datefile, dest, :level => level, :format => format,
                               :keep => 7, :symlink_original_filename => true)
        end
      end

      %w{debug info warn error fatal}.each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}(msg=nil, &block)
            @loggers.each {|l| l.#{method_name}(msg, &block) }
          end
        METHOD_DEFN
      end
    end
  end
end
Volley::Log.init
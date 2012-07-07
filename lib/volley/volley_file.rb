module Volley
  module VolleyFile
    class << self
      def init
        load("~/.Volleyfile", :optional => true)
      end

      def load(filename, options={ })
        @projects ||= { }
        file      = File.expand_path(filename)
        config.volleyfile = "#{Dir.pwd}/Volleyfile" if options[:primary]

        if File.file?(file)
          instance_eval(File.read(file), "Volleyfile")
          #Volley::Dsl::Project.class_eval(File.read(file), "#{Dir.pwd}/Volleyfile")
        else
          raise "cannot read file" unless options[:optional]
        end
      end

      def config
        Volley.config
      end

      # TOP LEVEL DSL METHODS

      def project(name, o={}, &block)
        Volley::Dsl::Project.project(name, o, &block)
      end

      def publisher(name, o={}, &block)
        Volley::Dsl::Publisher.publisher(name, o, &block)
      end
    end
  end
end
module Volley
  module VolleyFile
    class << self
      def init
        @loaded = {}
        ["/etc/Volleyfile", "~/.Volleyfile", "../../../conf/common.volleyfile"].each do |f|
          file = File.expand_path(f, __FILE__)
          @loaded[file] ||= load(file, :optional => true)
        end
      end

      def load(filename, options={ })
        Volley::Log.debug "LOAD: #{filename} #{options.inspect}"
        @projects ||= { }
        file      = File.expand_path(filename)
        config.volleyfile = file if options[:primary]

        if File.file?(file)
          @loaded[file] ||= instance_eval(File.read(file), file)
        else
          raise "cannot read file" unless options[:optional]
        end
      end

      # TOP LEVEL DSL METHODS

      def config
        Volley.config
      end

      def project(name, o={}, &block)
        Volley::Log.debug "project: #{name}"
        Volley::Dsl::Project.project(name, o, &block)
      end

      def publisher(name, o={}, &block)
        Volley::Dsl::Publisher.publisher(name, o, &block)
      end

      def log(level, dest)
        Volley::Log.add(level, dest)
      end

      def directory(dir)
        Volley.config.directory = dir
      end
    end
  end
end
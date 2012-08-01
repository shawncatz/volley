module Volley
  module VolleyFile
    class << self
      def init
        @loaded ||= { }

        ["/etc/Volleyfile", "~/.Volleyfile", "../../../conf/common.volleyfile"].each do |f|
          load(f, :optional => true)
        end
      end

      def load(filename, options={ })
        file = load_file(filename)
        raise "cannot read file #{file}" unless file || options[:optional]
        config.volleyfile = file if options[:primary]
        true
      end

      # TOP LEVEL DSL METHODS

      def config
        Volley.config
      end

      def project(name, o={ }, &block)
        Volley::Log.debug "project: #{name}"
        Volley::Dsl::Project.project(name, o, &block)
      end

      def publisher(name, o={ }, &block)
        Volley::Dsl::Publisher.publisher(name, o, &block)
      end

      def log(level, dest)
        Volley::Log.add(level, dest)
      end

      def directory(dir)
        Volley.config.directory = dir
      end

      private

      def load_file(filename)
        @loaded   ||= { }
        @projects ||= { }

        file = File.expand_path(filename, __FILE__)
        Volley::Log.debug "LOAD: [#{File.file?(file)}] #{filename}"
        return unless File.file?(file)
        @loaded[file] ||= instance_eval(File.read(file), file)
        file
      end
    end
  end
end
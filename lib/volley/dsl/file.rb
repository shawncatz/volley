module Volley
  module Dsl
    module VolleyFile
      class << self
        def init
          @loaded ||= { }

          ["/etc/Volleyfile", "~/.Volleyfile", "../../../../conf/common.volleyfile"].each do |f|
            load(f, :optional => true)
          end
        end

        def load(filename, options={ })
          file = load_file(filename)
          raise "cannot read file #{file}" unless file || options[:optional]
          config.volleyfile = file if options[:primary]
          true
        end

        def unload
          @loaded = nil
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

        def user(name)
          raise "user '#@user' already specified" if @user

          cuid = Process.euid
          raise "'user #{name}' called in configuration, but process uid is not root (0)" unless cuid == 0

          begin
            pw = Etc.getpwnam(name)
          rescue ArgumentError => e
            raise "could not find user '#{name}', check your Volleyfile configuration"
          end

          nuid = pw[:uid]

          if cuid != nuid
            puts "changing user id to: #{nuid} (from #{cuid})"
            Process::UID.change_privilege(nuid)
            @user = name
          end
        end

        def directory(dir)
          Volley.config.directory = dir
        end

        private

        def load_file(filename)
          @loaded   ||= { }
          @projects ||= { }

          file   = find_file(filename)
          exists = file && File.file?(file)
          Volley::Log.debug "LOAD: [#{exists}] #{filename} (#{file})"
          return unless exists
          @loaded[file] ||= instance_eval(File.read(file), file)
          file
        end

        def find_file(filename)
          return unless filename
          [filename, File.expand_path(filename), File.expand_path(filename, __FILE__)].each do |f|
            return f if File.file?(f)
          end
          nil
        rescue ArgumentError # rescue errors with expand path
          nil
        end
      end
    end
  end
end

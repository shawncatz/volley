module Volley
  module Publisher
    class Base
      attr_accessor :force

      def initialize(options={ })
        @options = {
            :overwrite => false,
        }.merge(options)

        @debug     = optional(:debug, false)
        @encrypted = optional(:encrypted, false)
        @local     = optional(:local, Volley.config.directory)
        @loglevel  = @debug ? :info : :debug
        @latest    = {}
        @force     = false

        load_configuration
      end

      def projects
        raise "not implemented"
      end

      def branches(project)
        raise "not implemented"
      end

      def versions(project, branch)
        raise "not implemented"
      end

      def exists?(project, branch, version)
        raise "not implemented"
      end

      def contents(project, branch, version)
        raise "not implemented"
      end

      def delete_project(project)
        raise "not implemented"
      end

      def latest(project, branch)
        @latest["#{project}/#{branch}"] ||= pull_file(dir(project,branch), "latest")
      end

      def latest_version(project, branch)
        latest(project, branch).split("/").last
      end

      def volleyfile(project, branch, version="latest")
        d = dir(project,branch,version)
        contents = pull_file(d, "Volleyfile")

        dest     = "#@local/Volleyfile-#{Time.now.to_i}-#{$$}"
        raise "File #{dest} already exists" if File.exists?(dest)

        log "saving Volleyfile: #{dest}"
        File.open(dest, "w") { |f| f.write(contents) }
        dest
      end

      def push(project, branch, version, localfiles)
        v = version == "latest" ? latest_version(project, branch) : version
        return false if exists?(project, branch, v) && !@force

        localfiles = [*localfiles].flatten
        log "^^ #{me}#push"

        dir = dir(project, branch, version)
        localfiles.each do |localfile|
          push_file(dir, localfile, File.open(localfile))
        end

        if Volley.config.volleyfile && File.file?(Volley.config.volleyfile)
          push_file(dir, "Volleyfile", File.open(Volley.config.volleyfile))
        end

        push_file(dir(project, branch), "latest", "#{project}/#{branch}/#{version}")

        true
      end

      def pull(project, branch, version="latest")
        dir = dir(project, branch, version)
        file = remote_file(branch, version)

        log "vv #{me}#pull"
        pull_file(dir, file, "#@local/#{dir}")

        "#@local/#{dir}/#{file}"
      end

      protected

      def me
        self.class.name.split("::").last
      end

      def requires(name)
        v = get_option(name)
        if v.nil?
          raise "Publisher #{me} requires option #{name}"
        end
        v
      end

      def optional(name, default)
        get_option(name) || default
      end

      def get_option(name)
        n = name.to_sym
        @options[n]
      end

      def get_config(name)
        n = name.to_sym
        Volley.config.send(n)
      end



      def push_file(dir, name, contents)
        raise "not implemented"
      end

      def pull_file(dir, name, localdir=nil)
        raise "not implemented"
      end

      def remote_file(branch, version)
        version = version == 'latest' ? latest(project, branch) : version
        "#{branch}-#{version}.tgz#{".cpt" if @encrypted}"
      end

      def dir(project, branch, version=nil)
        version = version == 'latest' ? latest_version(project, branch) : version
        [project, branch, version].compact.join("/")
      end

      def log(msg)
        Volley::Log.send(@loglevel, msg)
      end

    end
  end
end
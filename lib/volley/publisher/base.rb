module Volley
  module Publisher
    class Base
      def initialize(options={ })
        @options = {
            :overwrite => false,
        }.merge(options)
        load_configuration
      end

      def projects
        raise "not implemented"
      end

      def volleyfile(desc={ })
        @project = desc[:project]
        @branch  = desc[:branch]
        @version = desc[:version] && desc[:version] != 'latest' ? desc[:version] : get_latest(@project, @branch)
        contents = pull_file("Volleyfile", version)
        dest     = @options[:destination] || "/tmp/Volleyfile-#{Time.now.to_i}-#{$$}"
        raise "File #{dest} already exists" if File.exists?(dest)
        Volley::Log.debug("saving Volleyfile: #{dest}")
        File.open(dest, "w") { |f| f.write(contents) }
        dest
      end

      def push(project, br, ver, localfiles)
        @project = project
        @branch  = br
        @version = ver

        localfiles = [*localfiles].flatten
        Volley::Log.info ".. pushing:" if @debug

        localfiles.each do |localfile|
          Volley::Log.info ".. .. #{localfile}" if @debug
          push_file(localfile, version, File.open(localfile))
        end
        push_file("latest", branch, version)
        push_file("Volleyfile", version, File.open(Volley.config.volleyfile))
      end

      def pull(project, branch, ver="latest")
        @project = project
        @branch  = branch
        @version = ver

        if @version == "latest"
          @version = get_latest(@project, @branch)
        end

        Volley::Log.info "remote: #{version}" if @debug
        Volley::Log.info "remote_file: #{remote_file}" if @debug
        pull_file(remote_file, version, "#@local/#{version}")

        "#@local/#{version}/#{remote_file}"
      end

      def get_latest(project, branch)
        cur       = pull_file("latest", "#{project}/#{branch}")
        (p, n, v) = cur.split(/\//)
        v
      end

      private
      def me
        self.class.name.split("::").last
      end

      def branch
        "#@project/#@branch"
      end

      def version
        "#{branch}/#@version"
      end

      def requires(name)
        v = get_option(name)
        if v.nil?
          #ap @options
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
    end
  end
end
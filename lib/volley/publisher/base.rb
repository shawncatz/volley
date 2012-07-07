
module Volley
  module Publisher
    class Base
      def initialize(options={})
        @options = {}.merge(options)
        load_configuration
      end

      def push(project, name, ver, localfiles)
        @project = project
        @name = name
        @version = ver

        localfiles = [*localfiles].flatten
        puts ".. pushing:" if @debug

        localfiles.each do |localfile|
          puts ".. .. #{localfile}" if @debug
          push_file(localfile, version, File.open(localfile))
        end
        push_file("latest", branch, version)
      end

      def pull(project, name, ver="latest")
        @project = project
        @name = name
        @version = ver

        if @version == "latest"
          @version = get_latest(@project, @name)
        end

        puts "remote: #{version}" if @debug
        puts "remote_file: #{remote_file}" if @debug
        pull_file(remote_file, version, "#@local/#{version}")

        "#@local/#{version}/#{remote_file}"
      end

      def get_latest(project, name)
        cur       = pull_file("latest", "#{project}/#{name}")
        (p, n, v) = cur.split(/\//)
        v
      end

      private
      def me
        self.class.name.split("::").last
      end

      def branch
        "#@project/#@name"
      end

      def version
        "#{branch}/#@version"
      end

      def requires(name)
        v = get_option(name)
        if v.nil?
          ap @options
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
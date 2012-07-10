module Volley
  module Publisher
    class Local < Base

      private

      def load_configuration
        @directory = requires(:directory)
        @local     = requires(:local)
        @debug     = optional(:debug, false)
      end

      def remote_file
        "#@branch-#@version.tgz#{".cpt" if @encrypted}"
      end

      def push_file(local, path, content = nil)
        Volley::Log.info"content=#{content.inspect}"
        local = File.basename(local) if local =~ /^\//
        dest = "#@directory/#{path}"
        file = "#{dest}/#{local}"
        Volley::Log.info".. -> #{dest}"
        FileUtils.mkdir_p(File.dirname(file))
        content = content.read if content.is_a?(File)
        if content
          File.open(file, "w") { |f| f.write(content) }
        else
          FileUtils.copy(local, file)
        end
        Volley::Log.info".. => #{file}"
      end

      def pull_file(file, path, ldir=nil)
        remote = "#@directory/#{path}"
        Volley::Log.info".. <- #{remote}/#{file}"
        if ldir
          FileUtils.mkdir_p(ldir)
        end
        if ldir
          Volley::Log.info".. <= #@local/#{path}/#{file}"
          FileUtils.copy("#{remote}/#{file}", "#@local/#{path}")
        else
          File.open("#{remote}/#{file}") { |f| f.read }
        end
      end
    end
  end
end
module Volley
  module Publisher
    class Local < Base

      def projects
        Dir["#@directory/*"].map {|e| e.gsub(/#@directory\//,"")}
      end

      def branches(pr)
        Dir["#@directory/#{pr}/*"].map {|e| e.gsub(/#@directory\/#{pr}\//,"")}
      end

      def versions(pr, br)
        Dir["#@directory/#{pr}/#{br}/*"].map {|e| e.gsub(/#@directory\/#{pr}\/#{br}\//,"")}
      end

      def exists?(project, branch, version)
        d = "#@directory/#{project}/#{branch}/#{version}"
        Volley::Log.debug "exists? #{d}"
        File.directory?(d)
      end

      def delete_project(project)
        FileUtils.rm_rf("#@directory/#{project}")
        true
      rescue => e
        Volley::Log.error "error deleting project: #{e.message} at #{e.backtrace.first}"
        false
      end

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
        Volley::Log.debug "content=#{content.inspect}"
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
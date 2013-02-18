module Volley
  module Publisher
    class Local < Base

      def all
        #TODO: make this work like the S3 version
      end

      def projects
        l = Dir["#@directory/*"]
        l.map {|e| e.gsub(/#@directory\//,"")}
      end

      def branches(pr)
        Dir["#@directory/#{pr}/*"].map {|e| e.gsub(/#@directory\/#{pr}\//,"")}.reject {|e| ["latest_release"].include?(e)}
      end

      def versions(pr, br)
        Dir["#@directory/#{pr}/#{br}/*"].map do |e|
          e.gsub(/#@directory\/#{pr}\/#{br}\//,"")
        end.reject { |e| ["","latest","latest_release"].include?(e) }
      end

      def exists?(project, branch, version)
        d = "#@directory/#{project}/#{branch}/#{version}"
        File.directory?(d)
      end

      def contents(project, branch, version)
        d = "#@directory/#{project}/#{branch}/#{version}"
        Dir["#{d}/*"].map do |e|
          e.gsub("#{d}/","")
        end
      end

      def version_data(project, branch, version)
        pr    = project.to_s
        br    = branch.to_s
        vr    = version.to_s
        list  = Dir["#@directory/#{project}/#{branch}/#{version}/*"]
        files = contents(project, branch, version)
        time  = list.map { |e| File.mtime(e) }.sort.uniq.last
        {
            :contents  => files,
            :timestamp => time,
            :latest => (latest_version(project, branch) == vr)
        }
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
        @debug     = optional(:debug, false)
      end

      def push_file(dir, file, content = nil)
        file = File.basename(file) if file =~ /^\//
        dest = "#@directory/#{dir}/#{file}"
        FileUtils.mkdir_p(File.dirname(dest))
        content = content.read if content.is_a?(File)
        if content
          File.open(dest, "w") {|f| f.write(content)}
        else
          FileUtils.copy(file, dest)
        end
        log "=> #{dest}"
        dest
      end

      def pull_file(dir, file, localdir=nil)
        remote = "#@directory/#{dir}"
        raise ArtifactMissing, "missing: #{remote}" unless File.exists?("#{remote}/#{file}")

        log "<= #@local/#{dir}/#{file}"
        if localdir
          FileUtils.mkdir_p(localdir)
          FileUtils.copy("#{remote}/#{file}", "#@local/#{dir}")
        else
          File.read("#{remote}/#{file}")
        end
      end
    end
  end
end
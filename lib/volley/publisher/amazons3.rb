require 'fog'

module Volley
  module Publisher
    class Amazons3 < Base
      attr_accessor :key, :secret

      def all
        files[:all]
      end

      def projects
        r = files[:desc].keys || [] rescue []
        Volley::Log.info "could not find projects" unless r.count > 0
        r
      rescue => e
        Volley::Log.warn "error getting project list from publisher: #{e.message} at #{e.backtrace.first}"
        []
      end

      def branches(project)
        pr = project.to_s
        r = files[:desc][pr].keys || [] rescue []
        Volley::Log.info "could not find #{pr}" unless r.count > 0
        r
      rescue => e
        Volley::Log.warn "error getting branch list from publisher: #{e.message}"
        []
      end

      def versions(project, branch)
        pr = project.to_s
        br = branch.to_s
        r = files[:desc][pr][br].keys || [] rescue []
        Volley::Log.info "could not find #{pr}@#{br}" unless r.count > 0
        r.reject { |e| e == "latest" || e == "" }
      rescue => e
        Volley::Log.warn "error getting version list from publisher: #{e.message}"
        []
      end

      def version_data(project, branch, version)
        pr    = project.to_s
        br    = branch.to_s
        vr    = version.to_s
        list  = files[:desc][pr][br][vr]
        files = contents(project, branch, version)
        time  = list.map { |e| e.last_modified }.sort.uniq.last
        {
            :contents  => files,
            :timestamp => time,
            :latest => (latest_version(project, branch) == vr)
        }
      end

      def contents(project, branch, version)
        pr = project.to_s
        br = branch.to_s
        vr = version.to_s
        r = files[:desc][pr][br][vr].map { |e| e.key.gsub("#{pr}/#{br}/#{vr}/", "") } || [] rescue []
        Volley::Log.info "could not find #{pr}@#{br}:#{vr}" unless r.count > 0
        r
      rescue => e
        Volley::Log.warn "error getting contents list from publisher: #{e.message}"
        []
      end

      def exists?(project, branch, version)
        pr = project.to_s
        br = branch.to_s
        vr = version.to_s
        !files[:desc][pr][br][vr].nil?
      rescue => e
        Volley::Log.debug "exists? error: #{e.message}"
        false
      end

      def delete_project(project)
        Volley::Log.info "delete_project #{project}"
        dir = @connection.directories.get(@bucket)
        dir.files.select { |e| e.key =~ /^#{project}\// }.each do |f|
          Volley::Log.info "- #{f.key}"
          f.destroy
        end
        true
      rescue => e
        Volley::Log.error "error deleting project: #{e.message} at #{e.backtrace.first}"
        Volley::Log.debug e
        false
      end

      protected

      def load_configuration
        @key    = requires(:aws_access_key_id)
        @secret = requires(:aws_secret_access_key)
        @bucket = requires(:bucket)
        connect
      end

      def push_file(dir, file, contents)
        file = File.basename(file)
        dest = "#{dir}/#{file}"
        #log "-> #@bucket/#{path}"
        f    = root.files.create(:key => dest, :body => contents, :public => true)
        log "=> #{f.public_url.gsub("%2F", "/")}"
        dest
      end

      def pull_file(dir, file, localdir=nil)
        remote = "#{dir}/#{file}"
        f      = root.files.get(remote)
        raise ArtifactMissing, "missing: #{remote}" unless f

        contents = f.body

        log "<= #{dir}/#{file}"
        if localdir
          FileUtils.mkdir_p(localdir)
          local = "#{localdir}/#{file}"
          File.open(local, "w") { |lf| lf.write(contents) }
        else
          contents
        end
      end

      def root
        @root ||= @connection.directories.create({ :key => @bucket })
      end

      def connect
        @connection ||= Fog::Storage.new(
            :provider              => "AWS",
            :aws_access_key_id     => @key,
            :aws_secret_access_key => @secret,
        )
      end

      def files
        @files ||= begin
          hash = { :desc => { }, :all => { }, :latest => { } }
          @connection.directories.get(@bucket).files.each do |e|
            (pr, br, vr)            = e.key.split(/\//)
            hash[:desc][pr]         ||= { }
            hash[:desc][pr][br]     ||= { }
            hash[:desc][pr][br][vr] ||= []
            hash[:desc][pr][br][vr] << e
            hash[:all]    ||= { }
            hash[:latest] ||= { }
            v             = "#{pr}/#{br}/#{vr}"
            #hash[:latest]["#{pr}/#{br}"] ||= latest(pr, br)
            hash[:all][v] = hash["latest"] == v
          end
          #ap hash
          hash
        end
      end
    end
  end
end
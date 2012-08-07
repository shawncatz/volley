require 'fog'

module Volley
  module Publisher
    class Amazons3 < Base
      attr_accessor :key, :secret

      def projects
        files[:desc].keys
      rescue => e
        Volley::Log.warn "error getting project list from publisher: #{e.message} at #{e.backtrace.first}"
        []
      end

      def branches(pr)
        files[:desc][pr].keys
      rescue => e
        Volley::Log.warn "error getting branch list from publisher: #{e.message}"
        []
      end

      def versions(pr, br)
        files[:desc][pr][br].keys
      rescue => e
        Volley::Log.warn "error getting version list from publisher: #{e.message}"
        []
      end

      def contents(pr, br, vr)
        files[:desc][pr][br][vr].map {|e| e.gsub("#{pr}/#{br}/#{vr}/","")}
      rescue => e
        Volley::Log.warn "error getting contents list from publisher: #{e.message}"
        []
      end

      def exists?(project, branch, version)
        !files[:desc][project][branch][version].nil? rescue false
      end

      def delete_project(project)
        Volley::Log.info "delete_project #{project}"
        dir = @connection.directories.get(@bucket)
        dir.files.select{|e| e.key =~ /^#{project}\//}.each do |f|
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
        @key       = requires(:aws_access_key_id)
        @secret    = requires(:aws_secret_access_key)
        @bucket    = requires(:bucket)
        connect
      end

      def push_file(dir, file, contents)
        file = File.basename(file)
        dest = "#{dir}/#{file}"
        #log "-> #@bucket/#{path}"
        f = root.files.create(:key => dest, :body => contents, :public => true)
        log "=> #{f.public_url.gsub("%2F", "/")}"
        dest
      end

      def pull_file(dir, file, localdir=nil)
        remote = "#{dir}/#{file}"
        f = root.files.get(remote)
        raise ArtifactMissing, "missing: #{remote}" unless f

        contents = f.body

        if localdir
          FileUtils.mkdir_p(localdir)
          local = "#{localdir}/#{file}"
          log "<= #{local}"
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
        hash = {:desc => {}, :all => {}, :latest => {}}
        @connection.directories.get(@bucket).files.collect{|e| e.key}.each do |e|
          (pr, br, vr) = e.split(/\//)
          hash[:desc][pr] ||= {}
          hash[:desc][pr][br] ||= {}
          hash[:desc][pr][br][vr] ||= []
          hash[:desc][pr][br][vr] << e
          hash[:all] ||= {}
          hash[:latest] ||= {}
          v = "#{pr}/#{br}/#{vr}"
          #hash[:latest]["#{pr}/#{br}"] ||= latest(pr, br)
          hash[:all][v] = hash["latest"] == v
        end
        #ap hash
        hash
      end

      def all
        files[:all]
      end
    end
  end
end
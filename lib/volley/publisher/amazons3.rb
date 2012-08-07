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

      def versions(pr,br)
        files[:desc][pr][br].keys.map do |e|
          e == 'latest' ? "latest => #{files[:latest]["#{pr}/#{br}"]}" : e
        end
      rescue => e
        Volley::Log.warn "error getting version list from publisher: #{e.message}"
        []
      end

      def contents(pr, br, vr)
        files[:desc][pr][br][vr]
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

      def push_file(name, dir, contents)
        Volley::Log.debug ".. #{name}"
        file = File.basename(name)
        path = "#{dir}/#{file}"
        #Volley::Log.info "-> s3:#@bucket/#{path}"
        @dir        ||= @connection.directories.create({ :key => @bucket })
        s3f         = @dir.files.create(
            :key    => "#{path}",
            :body   => contents,
            :public => true
        )
        Volley::Log.info "=> #{s3f.public_url.gsub("%2F", "/")}"
        "#{path}"
      end

      def pull_file(name, dir, ldir=nil)
        #Volley::Log.info "<- s3:#@bucket/#{dir}/#{name}"
        if ldir
          FileUtils.mkdir_p(ldir)
        end
        f           = @connection.directories.get(@bucket).files.get("#{dir}/#{name}")
        raise "could not load file: #{dir}/#{name}" unless f
        contents    = f.body
        if ldir
          lfile = "#{ldir}/#{name}"
          File.open(lfile, "w") { |lf| lf.write(contents) }
          Volley::Log.info "<= #{lfile}"
        else
          contents
        end
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
          hash[:latest]["#{pr}/#{br}"] ||= latest(pr, br)
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
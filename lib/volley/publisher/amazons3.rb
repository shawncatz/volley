require 'fog'

module Volley
  module Publisher
    class Amazons3 < Base
      attr_accessor :key, :secret

      def files
        hash = {}
        @connection.directories.get(@bucket).files.collect{|e| e.key}.each do |e|
          (pr, br, vr) = e.split(/\//)
          hash[pr] ||= {}
          hash[pr][br] ||= {}
          hash[pr][br][vr] ||= []
          hash[pr][br][vr] << e
          hash["all"] ||= {}
          hash["latest"] ||= {}
          v = "#{pr}/#{br}/#{vr}"
          hash["latest"]["#{pr}/#{br}"] ||= latest(pr, br)
          hash["all"][v] = hash["latest"] == v
        end
        ap hash
        hash
      end

      def projects
        files.keys
        #files.collect{|e| e.split(/\//).first }.uniq
      rescue => e
        Volley::Log.warn "error getting project list from publisher"
        []
      end

      def branches(pr)
        files[pr].keys
        #files.select{|e| e.split(/\//).first == pr}.collect{|e| e.split(/\//)[1]}
      rescue => e
        Volley::Log.warn "error getting branch list from publisher"
        []
      end

      def versions(pr,br)
        files[pr][br].keys
        #raise "not implemented"
      rescue => e
        Volley::Log.warn "error getting version list from publisher"
        []
      end

      def contents(pr, br, vr)
        files[pr][br][vr]
      end

      def latest(pr, br)
        @project = pr
        @branch = br
        f = @connection.directories.get(@bucket).files.get("#{branch}/latest")
        f.body
      end

      private

      def load_configuration
        @key       = requires(:aws_access_key_id)
        @secret    = requires(:aws_secret_access_key)
        @bucket    = requires(:bucket)
        @local     = requires(:local)
        @debug     = optional(:debug, false)
        @encrypted = optional(:encrypted, false)
        connect
      end

      def remote_file
        "#@branch-#@version.tgz#{".cpt" if @encrypted}"
      end

      def push_file(name, dir, contents)
        Volley::Log.info ".. #{name}"
        file = File.basename(name)
        path = "#{dir}/#{file}"
        Volley::Log.info ".. -> s3:#@bucket/#{path}"
        @dir        ||= @connection.directories.create({ :key => @bucket })
        s3f         = @dir.files.create(
            :key    => "#{path}",
            :body   => contents,
            :public => true
        )
        Volley::Log.info ".. => #{s3f.public_url.gsub("%2F", "/")}"
        "#{path}"
      end

      def pull_file(name, dir, ldir=nil)
        Volley::Log.info ".. <- s3:#@bucket/#{dir}/#{name}"
        if ldir
          FileUtils.mkdir_p(ldir)
        end
        f           = @connection.directories.get(@bucket).files.get("#{dir}/#{name}")
        contents    = f.body
        if ldir
          lfile = "#{ldir}/#{name}"
          File.open(lfile, "w") { |lf| lf.write(contents) }
          Volley::Log.info ".. <= #{lfile}"
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
    end
  end
end
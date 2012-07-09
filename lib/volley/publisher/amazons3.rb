require 'fog'

module Volley
  module Publisher
    class Amazons3 < Base
      attr_accessor :key, :secret

      def load_configuration
        @key       = requires(:aws_access_key_id)
        @secret    = requires(:aws_secret_access_key)
        @bucket    = requires(:bucket)
        @local     = requires(:local)
        @debug     = optional(:debug, false)
        @encrypted = optional(:encrypted, false)
      end

      private

      def remote_file
        "#@name-#@version.tgz#{".cpt" if @encrypted}"
      end

      def push_file(name, dir, contents)
        Volley::Log.info ".. #{name}"
        file = File.basename(name)
        path = "#{dir}/#{file}"
        Volley::Log.info ".. -> s3:#@bucket/#{path}"
        @connection ||= Fog::Storage.new(
            :provider              => "AWS",
            :aws_access_key_id     => @key,
            :aws_secret_access_key => @secret,
        )
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
        @connection ||= Fog::Storage.new(
            :provider              => "AWS",
            :aws_access_key_id     => @key,
            :aws_secret_access_key => @secret,
        )
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
    end
  end
end
require 'fog'

module Volley
  module Publisher
    class Amazons3 < Base
      attr_accessor :key, :secret

      def load_configuration
        @key     = config(:aws_access_key_id)
        @secret  = config(:aws_secret_access_key)
        @bucket  = config(:bucket)
        @project = requires(:project)
        @name    = requires(:name)
        @version = requires(:version)
      end

      def push(localfiles)
        puts ".. pushing:"

        remote = "#@project/#@name/#@version"
        localfiles.each do |localfile|
          push_file(localfile, remote, File.open(localfile))
        end
        push_file("latest", "#@project/#@name", remote)
        #push_file("Volleyfile", "#@project/#@name", File.open("Volleyfile"))
      end

      def pull

      end

      private

      def push_file(name, dir, contents)
        puts ".. #{name}"
        file = File.basename(name)
        path = "#{dir}/#{file}"
        puts ".. -> s3:#@bucket/#{path}"
        @connection ||= Fog::Storage.new(
            :provider => "AWS",
            :aws_access_key_id => @key,
            :aws_secret_access_key => @secret,
        )
        @dir ||= @connection.directories.create({:key => @bucket})
        s3f = @dir.files.create(
            :key => "#{path}",
            :body => contents,
            :public => true
        )
        puts ".. => #{s3f.public_url.gsub("%2F","/")}"
        "#{path}"
      end
    end
  end
end
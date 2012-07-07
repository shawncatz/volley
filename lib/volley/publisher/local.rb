module Volley
  module Publisher
    class Local < Base

      #def push(localfiles)
      #  localfiles = [*localfiles].flatten
      #  puts ".. pushing:"
      #  remote = "#@project/#@name/#@version"
      #  localfiles.each do |localfile|
      #    push_file(localfile, "#@directory/#{remote}")
      #  end
      #  push_file("latest", "#@directory/#@project/#@name", remote)
      #end
      #
      #def pull
      #
      #end

      private

      def load_configuration
        @directory = requires(:directory)
        @local     = requires(:local)
        @debug     = optional(:debug, false)
      end

      #def remote
      #  "#@project/#@name/#@version"
      #end

      def remote_file
        "#@name-#@version.tgz#{".cpt" if @encrypted}"
      end

      def push_file(local, path, content = nil)
        puts "content=#{content.inspect}"
        local = File.basename(local) if local =~ /^\//
        dest = "#@directory/#{path}"
        file = "#{dest}/#{local}"
        puts ".. -> #{dest}"
        FileUtils.mkdir_p(File.dirname(file))
        content = content.read if content.is_a?(File)
        if content
          File.open(file, "w") { |f| f.write(content) }
        else
          FileUtils.copy(local, file)
        end
        puts ".. => #{file}"
      end

      def pull_file(file, path, ldir=nil)
        remote = "#@directory/#{path}"
        puts ".. <- #{remote}"
        if ldir
          FileUtils.mkdir_p(ldir)
        end
        if ldir
          puts ".. <= #@local/#{path}"
          #FileUtils.copy(remote, "#@local/#{path}")
        else
          File.open("#{remote}/#{file}") { |f| f.read }
        end
      end

      #def pull_file(name, dir, ldir=nil)
      #  puts ".. <- s3:#@bucket/#{dir}/#{name}"
      #  if ldir
      #    FileUtils.mkdir_p(ldir)
      #  end
      #  @connection ||= Fog::Storage.new(
      #      :provider              => "AWS",
      #      :aws_access_key_id     => @key,
      #      :aws_secret_access_key => @secret,
      #  )
      #  f           = @connection.directories.get(@bucket).files.get("#{dir}/#{name}")
      #  contents    = f.body
      #  if ldir
      #    lfile = "#{ldir}/#{name}"
      #    File.open(lfile, "w") { |lf| lf.write(contents) }
      #    puts ".. <= #{lfile}"
      #  else
      #    contents
      #  end
      #end
    end
  end
end
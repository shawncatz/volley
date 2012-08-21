require "volley/dsl/action"

module Volley
  module Dsl
    class PushAction < Action
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        @options = {
        }.merge(options)
        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan

        @plan.action :check, :pre do
          raise "branch(#{branch}) and version(#{version}) must be specified" unless branch && version
          p = @plan.project.name
          b = branch
          v = version
          if Volley::Dsl.publisher.exists?(p, b, v)
            log ".. artifact exists: #{p}@#{b}:#{v}"
            @plan.stop unless args.force
          end
        end

        @plan.action :files, :main do
          raise "branch(#{branch}) and version(#{version}) must be specified" unless branch && version

          list     = yield if block
          list     = [*list].flatten
          # use #exists? so it can work for directories
          notfound = list.reject { |f| File.exists?(f) }
          raise "built files not found: #{notfound.join(",")}" unless notfound.count == 0
          files list
          file Volley.config.volleyfile if Volley.config.volleyfile
        end

        if attributes.pack
          @plan.action :pack, :post do
            raise "branch(#{branch}) and version(#{version}) must be specified" unless branch && version

            path = attributes.pack_dir = "/var/tmp/volley-%d-%d-%05d" % [Time.now.to_i, $$, rand(99999)]
            Dir.mkdir(path)
            dir = Dir.pwd

            Volley::Log.debug ".. files: #{files.inspect}"
            files.each do |art|
              next unless art
              if art =~ /^\// && art !~ /^#{dir}/
                # file is full path and not in current directory
                source = art
                dest   = "#{path}/#{File.basename(art)}"
              else
                # file is relative path or in current directory
                f      = art.gsub(/^#{dir}/, "").gsub(/^\//, "")
                source = "#{dir}/#{f}"
                dest   = "#{path}/#{f}"
              end

              begin
                FileUtils.mkdir_p(File.dirname(dest))
                if File.directory?(source)
                  FileUtils.cp_r(source, dest)
                else
                  FileUtils.copy(source, dest)
                end
              rescue => e
                raise "could not copy file #{source}: #{e.message}"
              end
            end

            origpath = Dir.pwd
            Dir.chdir(path)
            case attributes.pack_type
              when "tgz"
                n = "#{branch}-#{version}.tgz"
                c = "tar cvfz #{n} *"
                Volley::Log.debug "command:#{c}"
                command(c)

                attributes.artifact = "#{path}/#{n}"
              else
                raise "unknown pack type '#{attributes.pack_type}'"
            end

            Dir.chdir(origpath)
          end
        end

        if attributes.encrypt
          @plan.action :encrypt, :post do
            art = attributes.artifact
            key = attributes.encrypt_key
            cpt = "#{art}.cpt"

            raise "in action encrypt: artifact file does not exist: #{art}" unless File.file?(art)
            raise "in action encrypt: encrypted file #{cpt} already exists" if File.file?(cpt) && !attributes.encrypt_overwrite
            shellout("ccrypt -e --key '#{key}' #{art}")

            attributes.artifact_unencrypted = art
            attributes.artifact             = cpt
          end
        end

        @plan.action :push, :post do
          publisher = Volley::Dsl.publisher
          publisher.push(project.name, branch, version, attributes.artifact)
        end
      end
    end
  end
end
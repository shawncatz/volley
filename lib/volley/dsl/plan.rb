require 'tempfile'

module Volley
  module Dsl
    class Plan
      attr_accessor :rawargs
      attr_reader :project
      attr_reader :stages
      attr_reader :arguments
      attr_reader :attributes

      def initialize(name, o={ }, &block)
        options = {
            :name      => name,
            :project   => nil,
            :output    => false,
            :encrypt   => false,
            :remote    => true,
            :pack      => true,
            :pack_type => "tgz",
        }.merge(o)
        @attributes  = OpenStruct.new(options)
        raise "project instance must be set" if @attributes.project.nil?

        @name        = name.to_sym
        @project     = options[:project]
        @block       = block
        @files       = []
        @arguments   = { }
        @stages      = {
            :pre  => Volley::Dsl::Stage.new(:pre, :plan => self),
            :main => Volley::Dsl::Stage.new(:main, :plan => self),
            :post => Volley::Dsl::Stage.new(:post, :plan => self),
        }
        @stage_order = [:pre, :main, :post]

        instance_eval &block if block_given?

        if @attributes.remote
          argument :branch, :default => nil do |v|
            v || source.branch || nil
          end
          argument :version, :default => "latest" do |v|
            !v || v == "latest" ? source.revision : v
          end
        end
      end

      def call(options={ })
        Volley::Log.debug "## #{@project.name} : #@name"
        @origargs = options[:rawargs]
        process_arguments(options[:rawargs])
        #instance_eval &@block
        run_actions
        [args.branch, args.version].join(":")
      end

      def full_usage
        out = []
        @argdefs.each do |n, arg|
          t = arg[:convert] || "string"
          r = arg[:required]
          #o = "#{n}:#{t}"
          #o = "[#{o}]" unless r
          d = arg[:default] ? "default: #{arg[:default]}" : ""
          o = "%15s %15s %1s %s" % [n, t, (r ? '*' : ''), d]
          out << "#{o}"
        end
        out
      end

      def usage
        out = []
        @argdefs.each do |n, arg|
          t = arg[:convert] || "string"
          r = arg[:required]
          d = arg[:default] ? "#{arg[:default]}" : ""
          v = arg[:choices] ? "[#{arg[:choices].join(",")}]" : "<#{n}>"
          out << "#{n}:#{v}#{"*" if r}"
        end
        out.join(" ")
      end

      def run_actions(*stages)
        @stage_order.each do |stage|
          @stages[stage].call
        end
        #stages = [*stages].flatten
        #stages = [:pre, :main, :post] if stages.count == 0
        #stages.each do |stage|
        #  if @actions[stage].count > 0
        #    @actions[stage].each do |act|
        #      Volley::Log.debug ".. #{@project.name}[#{stage}]:#{act[:name].to_s.split("-").join(" ")}"
        #      begin
        #        Volley::Log.debug ".. .. before"
        #        self.instance_eval(&act[:block])
        #        Volley::Log.debug ".. .. after"
        #      rescue => e
        #        Volley::Log.error "error running action: #{act[:name]}: #{e.message} at #{e.backtrace.first}"
        #        Volley::Log.debug e
        #        raise e
        #      end
        #    end
        #  end
        #end
      end

      def method_missing(n, *args)
        Volley::Log.warn "** plan DSL does not support method: #{n} #{args.join(',')}"
        raise "not supported"
      end

      def args
        @args = OpenStruct.new(@arguments.inject({ }) { |h, e| (k, v)=e; h[k] = v.value; h })
      end

      def source
        @project.source or raise "SCM not configured"
      end

      def log(msg)
        Volley::Log.info msg
      end

      def load(file)
        Volley::Dsl.file(file)
      rescue => e
        Volley::Log.error "failed to load file: #{e.message}: #{file} (#{real})"
        Volley::Log.debug e
      end

      def config
        Volley.config
      end

      def argument(name, opts={ }, &block)
        @arguments[name.to_sym] = Volley::Dsl::Argument.new(name, opts.merge(:plan => self), &block)
      end

      def output(tf=true)
        @attributes.output = tf
        argument :output, :attr => true, :default => tf, :convert => :boolean
      end

      def default(&block)
        action(:default, :main, &block)
      end

      def action(name, stage=:main, &block)
        @stages[stage].action(name, :plan => self, :stage => stage, &block)
        #n = name.to_sym
        #@actions[stage] << { :name => n, :stage => stage, :block => block }
      end

      def file(file)
        @files << file
      end

      def files(*list)
        list = [*list].flatten
        if @files.count > 0 && list.count > 0
          Volley::Log.warn "overriding file list"
          Volley::Log.debug "files: #{@files.inspect}"
          Volley::Log.debug "new: #{list.inspect}"
        end
        @files = list if list.count > 0
        @files
      end

      def push(&block)
        action :files, :post do
          list     = yield
          list     = [*list].flatten
          # use #exists? so it can work for directories
          notfound = list.reject { |f| File.exists?(f) }
          raise "built files not found: #{notfound.join(",")}" unless notfound.count == 0
          files list
          file Volley.config.volleyfile if Volley.config.volleyfile
        end

        if attributes.pack
          action :pack, :post do
            path = attributes.pack_dir = "/var/tmp/volley-%d-%d-%05d" % [Time.now.to_i, $$, rand(99999)]
            Dir.mkdir(path)
            dir = Dir.pwd

            files.each do |art|
              Volley::Log.debug "art:#{art}"
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
                Volley::Log.debug "pack file: #{source} => #{dest}"
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
                n = "#{args.branch}-#{args.version}.tgz"
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
          action :encrypt, :post do
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

        action :push, :post do
          publisher = Volley::Dsl.publisher
          publisher.push(project.name, args.branch, args.version, attributes.artifact)
        end
      end

      def pull
        dir  = nil
        pub  = nil
        file = nil
        tgz  = nil

        action :download do
          pr = project.name
          br = args.branch
          ve = args.version

          pub  = Volley::Dsl.publisher
          raise "publisher must be defined" unless pub
          file = pub.pull(pr, br, ve)

          dir = File.dirname(file)
        end

        action :unpack do
          FileUtils.mkdir_p("#{dir}/unpack")
          Volley::Log.info "changing directory: #{dir} (#{file})"
          Dir.chdir("#{dir}/unpack")
          tgz = %x{tar xvfz #{file} 2>/dev/null}
          File.open("#{dir}/tgz.log", "w") { |f| f.write(tgz) }
        end

        action :run do
          raise "failed to unpack: #{dir}/unpack" unless dir && File.directory?("#{dir}/unpack")
          yield "#{dir}/unpack"
        end
      end

      def volley(opts={ })
        o = {
            :project => @project.name,
            :plan    => "pull",
        }.merge(opts)

        action "volley-#{o[:project]}-#{o[:plan]}" do
          options = { :branch => args.branch||source.branch, :version => args.version||source.revision, :args => @origargs }.merge(o)
          Volley.process(options)
        end
      end

      def command(*args)
        name = args.join(" ").parameterize.to_sym
        action name do
          shellout(*args)
        end
      end

      def shellout(*args)
        require "mixlib/shellout"
        opts    = args.last.is_a?(Hash) ? args.pop : { }
        options = {
            :output  => @attributes.output,
            :prepend => ">> ",
        }.merge(opts)
        command = ::Mixlib::ShellOut.new(*args)
        command.run_command
        command.stdout.lines.each { |l| Volley::Log.info "#{options[:prepend]}#{l}" } if options[:output] && command.stdout
        command.stderr.lines.each { |l| Volley::Log.info "#{options[:prepend]}#{l}" } if options[:output] && command.stderr
        command.error!
        { :out => command.stdout, :err => command.stderr }
      end

      private
      def process_arguments(raw)
        Volley::Log.debug ".. process arguments: #{raw.inspect}"
        if raw
          kvs = raw.select { |e| e =~ /\:/ }
          raw = raw.reject { |e| e =~ /\:/ }
          @rawargs = raw
          #@argdata = kvs.inject({ }) { |h, a| (k, v) = a.split(/:/); h[k.to_sym]= v; h }
          kvs.each do |a|
            (k, v) = a.split(/:/)
            if @arguments[k.to_sym]
              Volley::Log.debug ".. .. setting argument: #{k} = #{v}"
              @arguments[k.to_sym].value = v
            end
          end
        end
        #@args = OpenStruct.new(@arguments.inject({ }) { |h, e| (k, v)=e; h[k] = v.value; h })
      end
    end
  end
end
require 'tempfile'

module Volley
  module Dsl
    class Plan
      def initialize(name, o={ }, &block)
        options    = {
            :name      => name,
            :output    => false,
            :project   => nil,
            :encrypt   => false,
            :pack      => true,
            :pack_type => "tgz",
        }.merge(o)
        raise "project instance must be set" if options[:project].nil?
        @project = options[:project]
        @block = block
        @attributes = OpenStruct.new(options)
        @args       = OpenStruct.new
        @actions    = []
      end

      def call(options)
        @cliargs    = options[:cliargs].inject({ }) { |h, a| (k, v) = a.split(/:/); h[k.to_sym]= v; h } if options[:cliargs]
        instance_eval &@block
        run_actions
      end

      def run_actions
        ap Volley.config if Volley.config.debug
        puts "running actions..."
        @actions.each do |act|
          puts "running action: #{act[:name]}"
          ap act if Volley.config.debug
          self.instance_eval(&act[:block])
        end
        ap self if Volley.config.debug
      end

      def method_missing(n, *args)
        puts "mm: #{n} #{args.join(',')}"
      end

      def args
        @args
      end

      def argument(name, opts={ })
        n = name.to_sym
        # had to make this more complex to handle valid "false" values
        v = begin
          if @cliargs[n].nil?
            if opts[:default].nil?
              nil
            else
              opts[:default]
            end
          else
            @cliargs[n]
          end
        end
        raise "arg '#{name}' is required, but not set" if opts[:required] && v.nil?
        if opts[:convert]
          if opts[:convert] == :boolean
            v = boolean(v)
          else
            v = v.send(opts[:convert])
          end
        elsif block_given?
          v = yield v
        end
        raise "arg '#{name}' is required, but not set (after convert)" if opts[:required] && v.nil?
        @args.send("#{n}=", v)
        @attributes.send("#{n}=", v) if opts[:attr]
      end

      def output(tf=true)
        @attributes.output = tf
        argument :output, :attr => true, :default => tf, :convert => :boolean
      end

      def action(name, &block)
        n = name.to_sym
        @actions << { :name => n, :block => block }
      end

      def build(&block)
        action :build do
          list     = begin
            case block.arity
              when 1
                yield @attributes.dup
              else
                yield
            end
          end
          list     = [*list].flatten
          notfound = list.reject { |f| File.file?(f) }
          raise "built files not found: #{notfound.join(",")}" unless notfound.count == 0
          @attributes.artifact_list = list
          @attributes.artifact_list << Volley.config.volleyfile
        end

        if @attributes.pack
          action :pack do
            path = @attributes.pack_dir = "/var/tmp/volley-#{Time.now.to_i}-#{$$}"
            Dir.mkdir(path)
            dir = Dir.pwd

            @attributes.artifact_list.each do |art|
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
                puts "pack file: #{source} => #{dest}" if Volley.config.debug
                FileUtils.mkdir_p(File.dirname(dest))
                FileUtils.copy(source, dest)
              rescue => e
                raise "could not copy file #{file}: #{e.message}"
              end
            end

            Dir.chdir(path)
            case @attributes.pack_type
              when "tgz"
                n = "#{args.name}-#{args.version}.tgz"
                c = "tar cvfz #{n} *"
                puts "command:#{c}" if Volley.config.debug
                shellout(c)

                @attributes.artifact = "#{path}/#{n}"
              else
                raise "unknown pack type '#{@attributes.pack_type}'"
            end
          end
        end

        if @attributes.encrypt
          action :encrypt do
            art = @attributes.artifact
            key = @attributes.encrypt_key
            cpt = "#{art}.cpt"

            raise "in action encrypt: artifact file does not exist: #{art}" unless File.file?(art)
            raise "in action encrypt: encrypted file #{cpt} already exists" if File.file?(cpt) && !@attributes.encrypt_overwrite
            shellout("ccrypt -e --key '#{key}' #{art}")

            @attributes.artifact_unencrypted = art
            @attributes.artifact             = cpt
          end
        end
      end

      def push(pub_name)
        action :push do
          publisher = Volley::Dsl::Publisher.publisher(pub_name)
          publisher.push(@project.name, args.name, args.version, @attributes.artifact)
        end
      end

      def volley(opts={ })
        o          = {
            :project => @attributes.project,
            :name    => args.name,
            :version => "current",
            :plan    => "deploy",
        }.merge(opts)
        actionname = [o[:project], o[:name], o[:version], o[:plan]].join("-")
        action actionname do
          puts "VOLLEY: #{o[:project]} #{o[:name]} #{o[:version]} #{o[:plan]}"
          #shellout("")
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
        command = ::Mixlib::ShellOut.new(*args)
        command.run_command
        command.stdout.lines.each { |l| puts ".. out: #{l}" } if @attributes.output && command.stdout
        command.stderr.lines.each { |l| puts ".. err: #{l}" } if @attributes.output && command.stderr
        command.error!
        { :out => command.stdout, :err => command.stderr }
      end

      private

      def boolean(value)
        case value.class
          when TrueClass, FalseClass
            return value
          else
            return true if value =~ /^(1|t|true|y|yes)$/
            return false if value =~ /^(0|f|false|n|no)$/
        end
        nil
      end
    end
  end
end
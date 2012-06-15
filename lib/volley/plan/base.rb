require 'tempfile'

module Volley
  module Plan
    class Base
      attr_accessor :args
      attr_reader :attributes

      def initialize(name, opts = { })
        defaults    = {
            :name      => name,
            :publisher => nil,
            :encrypt   => false,
        }
        @attributes = OpenStruct.new(defaults.merge(opts))
        @actions    = []
        @args       = OpenStruct.new
        @cliargs    ||= opts[:cliargs].inject({ }) { |h, a| (k, v) = a.split(/:/); h[k.to_sym]= v; h }
      end

      def process(&block)
        if block_given?
          case block.arity
            when 2
              yield self, @attributes.dup
            when 1
              yield @attributes.dup
            else
              yield
          end
        end
      end

      def run(tmp=nil)
        ap config if config.debug
        puts "running actions..."
        @actions.each do |act|
          puts "running action: #{act[:name]}"
          ap act if config.debug
          self.instance_eval(&act[:block])
        end
        ap self if config.debug
      end

      # PLAN DSL

      # OPTIONS and ARGUMENTS

      def argument(name, opts={ })
        n = name.to_sym
        v = opts[:default] || nil
        v ||= @cliargs[n] || nil
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

      def config
        Volley.config
      end

      def output(type=true)
        @attributes.output = type
        argument :output, :attr => true, :default => type, :convert => :boolean
      end

      # ACTIONS

      def action(name, &block)
        n = name.to_sym
        @actions << { :name => n, :block => block }
      end

      def build(&block)
        action :build do
          list = begin
            case block.arity
              when 1
                yield @attributes.dup
              else
                yield
            end
          end
          notfound = list.reject{|f| File.file?(f) }
          unless list.kind_of?(Array) && notfound.count == 0
            raise "build action (in Volleyfile) must return a list of artifact paths. received: #{list} (not found: #{notfound.inspect})"
          end
          @attributes.artifacts = list
        end

        if @attributes.encrypt
          action :encrypt do
            @attributes.artifacts_unencrypted = @attributes.artifacts
            @attributes.artifacts             = []
            key                               = @attributes.encrypt_key

            @attributes.artifacts_unencrypted.each do |art|
              cpt = "#{art}.cpt"

              raise "in action encrypt: encrypted file #{cpt} already exists" if File.file?(cpt) && !@attributes.encrypt_overwrite
              shellout("ccrypt -e --key '#{key}' #{art}")

              @attributes.artifacts << cpt
            end
          end
        end
      end

      def encrypt(enable=false, opts={ })
        options = {
            :overwrite => false,
            :key       => "",
        }.merge(opts)

        @attributes.encrypt           = enable
        @attributes.encrypt_overwrite = options[:overwrite]

        key = options[:key]

        if File.file?(key)
          key = File.read(key).chomp
        end

        @attributes.encrypt_key = key
        #argument :encrypt, :attr => true, :default => enable, :convert => :boolean do |value|
        #  unless value
        #    @actions.delete_if {|e| e[:name] == :encrypt}
        #  end
        #  ap actions
        #  value
        #end
      end

      def push(name, o={ })
        publisher(name)
        action :push do
          options = {
              :project => config.project,
              :name    => args.name,
              :version => args.version,
          }.merge(o)
          klass   = @attributes.publisher_klass
          pusher  = klass.constantize.new(options)
          pusher.push(@attributes.artifacts)
        end
      end

      def pull(name)
        publisher(name)
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
        {:out => command.stdout, :err => command.stderr}
      end

      private

      def publisher(name)
        raise "publisher set multiple times: #{@attributes.publisher}, #{name}" if @attributes.publisher
        @attributes.publisher       = name
        klass                       = "Volley::Publisher::#{name.capitalize}"
        @attributes.publisher_klass = klass
        puts "loading publisher: #{name} (#{klass})" if config.debug
        require "volley/publisher/#{name}"
      end

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
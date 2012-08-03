require 'tempfile'

module Volley
  module Dsl
    class Plan
      attr_accessor :argv
      attr_reader :project
      attr_reader :stages
      attr_reader :arguments
      attr_reader :attributes

      def initialize(name, o={ }, &block)
        options     = {
            :name      => name,
            :project   => nil,
            :output    => false,
            :encrypt   => false,
            :remote    => true,
            :pack      => true,
            :pack_type => "tgz",
        }.merge(o)
        @attributes = OpenStruct.new(options)
        raise "project instance must be set" if @attributes.project.nil?

        @name        = name.to_sym
        @project     = options[:project]
        @block       = block
        @files       = []
        @arguments   = { }
        @argv        = []
        @stages      = {
            :pre  => Volley::Dsl::Stage.new(:pre, :plan => self),
            :main => Volley::Dsl::Stage.new(:main, :plan => self),
            :post => Volley::Dsl::Stage.new(:post, :plan => self),
        }
        @stage_order = [:pre, :main, :post]

        instance_eval &block if block_given?

        if @attributes.remote
          argument :descriptor, :required => true, :convert => :descriptor
        else
          argument :descriptor, :convert => :descriptor, :convert_opts => { :partial => true }
        end
      end

      def call(options={ })
        Volley::Log.debug "## #{@project.name} : #@name"
        @origargs = options[:args]
        data      = @origargs

        process_arguments(data)

        raise "descriptor must be specified" if @attributes.remote && !args.descriptor
        #raise "cannot determine branch" unless branch
        #raise "cannot determine version" unless version

        run_actions
        [branch, version].join(":")
      end

      def usage
        out = []
        @arguments.each do |n, arg|
          out << arg.usage
        end
        out.join(" ")
      end

      def run_actions(*stages)
        @stage_order.each do |stage|
          @stages[stage].call
        end
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

      def remote(tf)
        raise "remote can only be set to true or false" unless [true,false].include?(tf)
        @attributes.remote = tf
      end

      def branch
        (args.descriptor ? args.descriptor.branch : nil) || source.branch || nil
      end

      def version
        v = args.descriptor ? args.descriptor.version : nil
        if v == "latest"
          v = source.version || nil
        end
        v
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
        Volley::Dsl::PushAction.new(:push_dummy, :plan => self, :stage => :main, &block)
      end

      def pull(&block)
        Volley::Dsl::PullAction.new(:pull_dummy, :plan => self, :stage => :main, &block)
      end

      def volley(opts={ })
        o = {
            :project => @project.name,
            :plan    => "pull",
        }.merge(opts)

        action "volley-#{o[:project]}-#{o[:plan]}" do
          options = { :plan => "#{project}:#{plan}", :descriptor => "#{project}@#{branch}:#{version}", :args => @origargs }.merge(o)
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
          kvs   = raw.select { |e| e =~ /\:/ }
          raw   = raw.reject { |e| e =~ /\:/ }
          @argv = raw
          kvs.each do |a|
            (k, v) = a.split(/:/)
            if @arguments[k.to_sym]
              Volley::Log.debug ".. .. setting argument: #{k} = #{v}"
              @arguments[k.to_sym].value = v
            end
          end
        end
        @arguments.each do |k, v|
          v.check
        end
      end
    end
  end
end
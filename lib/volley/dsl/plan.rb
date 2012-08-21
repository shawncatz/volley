require 'tempfile'

module Volley
  module Dsl
    class Plan
      attr_accessor :argv
      attr_reader :name
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
        @stopped     = false
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
        argument :force
      end

      def call(options={ })
        @mode = @name.to_s =~ /deploy/i ? :deploy : :publish
        Volley::Log.debug "## #{@project.name}:#@name  (#@mode)"
        @origargs = options[:args]
        data      = @origargs

        process_arguments(data)

        raise "descriptor must be specified" if @attributes.remote && !args.descriptor

        Volley::Log.info ">> #{@project.name}:#@name"

        begin
          run_actions
        rescue => e
          puts "plan#call error: #{e.message} at #{e.backtrace.first}"
          ap self
          raise e
        end
        [branch, version].join(":")
      end

      def deploying?
        @mode == :deploy
      end

      def publishing?
        @mode == :publish
      end

      def usage
        out = []
        @arguments.each do |n, arg|
          out << arg.usage
        end
        out.join(" ")
      end

      def run_actions
        @stage_order.each do |stage|
          @current_stage = stage
          @stages[stage].call
        end
      end

      def stop
        @stopped = true
      end

      def stopped?
        @stopped
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
        raise "remote can only be set to true or false" unless [true, false].include?(tf)
        @attributes.remote = tf
      end

      def branch
        return args.descriptor.branch if args.descriptor
        return source.branch if publishing?
        nil
      end

      def version
        v = args.descriptor ? args.descriptor.version : nil
        if v.nil? || v == "latest"
          v = begin
            if deploying?
              Volley::Dsl.publisher.latest_version(args.descriptor.project, args.descriptor.branch) || v
            elsif publishing?
              source.revision || v
            end
          rescue => e
            Volley::Log.debug "failed to get version? #{v.inspect} : #{e.message}"
            Volley::Log.debug e
            v
          end
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

      def action(name, stage=:main, &block)
        @stages[stage].action(name, :plan => self, :stage => stage, &block)
      end

      def default(&block)
        action(:default, :main, &block)
      end

      def push(&block)
        Volley::Dsl::PushAction.new(:push_dummy, :plan => self, :stage => :main, &block)
      end

      def pull(&block)
        Volley::Dsl::PullAction.new(:pull_dummy, :plan => self, :stage => :main, &block)
      end

      def volley(plan, options={}, &block)
        o = {
            :run => plan,
            :plan => self,
            :stage => :main,
            :descriptor => args.descriptor,
            :args => {},
        }.merge(options)
        action = Volley::Dsl::VolleyAction.new("volley-#{plan}", o)
        #if @current_stage == :post
        #  action.call
        #else
          @stages[:main].add action
        #end
      end

      def file(file)
        @files << file
      end

      def files(*list)
        list = [*list].flatten
        list.each {|e| file e} if list.count > 0
        #if @files.count > 0 && list.count > 0
        #  Volley::Log.warn "overriding file list"
        #  Volley::Log.debug "files: #{@files.inspect}"
        #  Volley::Log.debug "new: #{list.inspect}"
        #end
        #@files = list if list.count > 0
        #@files
        @files
      end

      def command(*args)
        name = args.join(" ").parameterize.to_sym
        action name do
          plan.shellout(*args)
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
        @argv = raw
        raw.each do |k, v|
          if @arguments[k.to_sym]
            Volley::Log.debug ".. argument: #{k} = #{v}"
            @arguments[k.to_sym].value = v
          end
        end
        @arguments.each do |k, v|
          v.check
        end
        if @arguments[:force] && Volley::Dsl.publisher
          Volley::Dsl.publisher.force = true
        end
      end
    end
  end
end
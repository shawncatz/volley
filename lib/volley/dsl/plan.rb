require 'tempfile'

module Volley
  module Dsl
    class Plan
      def initialize(name, o={ }, &block)
        options = {
            :name      => name,
            :output    => false,
            :project   => nil,
            :encrypt   => false,
            :pack      => true,
            :pack_type => "tgz",
        }.merge(o)
        raise "project instance must be set" if options[:project].nil?
        @project    = options[:project]
        @block      = block
        @attributes = OpenStruct.new(options)
        @args       = OpenStruct.new
        @argdefs    = {}
        @argdata    = {}
        @actions    = {:pre => [], :main => [], :post => []}
        instance_eval &block if block_given?
      end

      def call(options={})
        @cliargs = options[:cliargs]
        @argdata = @cliargs.inject({ }) { |h, a| (k, v) = a.split(/:/); h[k.to_sym]= v; h } if @cliargs
        #instance_eval &@block
        run_actions
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
        stages = [*stages].flatten
        stages = [:pre, :main, :post] if stages.count == 0
        ap Volley.config if Volley.config.debug
        stages.each do |stage|
          Volley::Log.debug "running actions[:#{stage}]:" if @actions[stage].count > 0
          @actions[stage].each do |act|
            Volley::Log.info "running action: #{act[:name]}"
            ap act if Volley.config.debug
            self.instance_eval(&act[:block])
          end
        end
        ap self if Volley.config.debug
      end

      def method_missing(n, *args)
        Volley::Log.warn "** plan DSL does not support method: #{n} #{args.join(',')}"
        raise "not supported"
      end

      def args
        @args
      end

      def source
        @project.source or raise "SCM not configured"
      end

      def argument(name, opts={ })
        @argdefs[name] = opts
        action "argument-#{name}", :pre do
          n = name.to_sym
          # had to make this more complex to handle valid "false" values
          v = begin
            if @argdata[n].nil?
              if opts[:default].nil?
                nil
              else
                opts[:default]
              end
            else
              @argdata[n]
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
      end

      def output(tf=true)
        @attributes.output = tf
        argument :output, :attr => true, :default => tf, :convert => :boolean
      end

      def default(&block)
        action(:default, :main, &block)
      end

      def action(name, stage=:main, &block)
        n = name.to_sym
        @actions[stage] << { :name => n, :stage => stage, :block => block }
      end

      def push(&block)
        action :files do
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
                Volley::Log.debug "pack file: #{source} => #{dest}"
                FileUtils.mkdir_p(File.dirname(dest))
                FileUtils.copy(source, dest)
              rescue => e
                raise "could not copy file #{file}: #{e.message}"
              end
            end

            origpath = Dir.pwd
            Dir.chdir(path)
            case @attributes.pack_type
              when "tgz"
                n = "#{args.branch}-#{args.version}.tgz"
                c = "tar cvfz #{n} *"
                Volley::Log.debug "command:#{c}"
                shellout(c)

                @attributes.artifact = "#{path}/#{n}"
              else
                raise "unknown pack type '#{@attributes.pack_type}'"
            end

            Dir.chdir(origpath)
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

        action :push do
          publisher = Volley::Dsl.publisher
          publisher.push(@project.name, args.branch, args.version, @attributes.artifact)
        end
      end

      #def pull
      #  action :download do
      #    pr = @project.name
      #    br = args.branch
      #    ve = args.version
      #
      #    pub = Volley::Dsl.publisher
      #    file = pub.pull(pr, br, ve)
      #
      #    dir = File.dirname(file)
      #    Volley::Log.info "changing directory: #{dir} (#{file})"
      #    cmd = "volley run #{pr}:#{plan} branch:#{branch} #{arg_list.join(' ')}"
      #
      #    Volley::Log.info "command: #{cmd}"
      #    FileUtils.mkdir_p("#{dir}/unpack")
      #    Dir.chdir("#{dir}/unpack")
      #    tgz = %x{tar xvfz #{file} 2>/dev/null}
      #    File.open("#{dir}/tgz.log", "w") {|f| f.write(tgz)}
      #  end
      #end

      #def volley(opts={ })
      #  o = {
      #      :project => @project.name,
      #      :branch  => args.branch,
      #      :version => "latest",
      #      :plan    => "pull",
      #  }.merge(opts)
      #
      #  desc = [o[:project], o[:branch], o[:version], o[:plan]].compact.join(":")
      #  actionname = "volley-#{desc}"
      #  action actionname do
      #    Volley::Log.info "VOLLEY: #{desc}"
      #    cmd = ["volley"]
      #    cmd << desc
      #    shellout(cmd.join(" "), :output => true)
      #  end
      #end

      def volley(opts={ })
        o = {
            :project => @project.name,
            #:branch  => args.branch,
            #:version => "latest",
            :plan    => "pull",
        }.merge(opts)

        pr = o[:project]
        pl = o[:plan]

        action "volley-#{pr}-#{pl}" do
          plan = Volley::Dsl.project(pr).plan(pl)
          plan.call(:cliargs => @cliargs)
        end

        #desc = [o[:project], o[:branch], o[:version], o[:plan]].compact.join(":")
        #actionname = "volley-#{desc}"
        #action actionname do
        #  Volley::Log.info "VOLLEY: #{desc}"
        #  cmd = ["volley"]
        #  cmd << desc
        #  shellout(cmd.join(" "), :output => true)
        #end
      end

      def command(*args)
        name = args.join(" ").parameterize.to_sym
        action name do
          shellout(*args)
        end
      end

      def shellout(*args)
        require "mixlib/shellout"
        opts = args.last.is_a?(Hash) ? args.pop : {}
        options = {
            :output => @attributes.output,
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
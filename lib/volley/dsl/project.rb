
module Volley
  module Dsl
    class Project
      class << self
        attr_reader :projects
        def project(name, o={}, &block)
          n = name.to_sym
          @projects ||= {}
          if @projects[n]
            raise "defining project #{name} more than once"
          else
            @projects[n] = new(n)
            @projects[n].instance_eval &block if block_given?
          end
          @projects[n]
        end

        def get(name)
          @projects[name.to_sym]
        end

        def config
          Volley.config
        end

        def exists?(name)
          n = name.to_sym
          @projects.keys.include?(n)
        end

        def unload
          @projects = nil
        end
      end

      attr_reader :plans
      attr_reader :name

      def initialize(name)
        @name = name
        @plans = {}
      end

      def config
        Volley.config
      end

      def log(msg)
        Volley::Log.info msg
      end

      def plan(name, o={}, &block)
        n = name.to_sym
        options = {
            :project => self
        }.merge(o)
        if block_given?
          @plans[n] ||= Volley::Dsl::Plan.new(name, options, &block)
        end
        @plans[n]
      end

      def plan?(name)
        n = name.to_sym
        @plans.keys.include?(n)
      end

      def scm(name, o={}, &block)
        options = {
            :required => true,
        }.merge(o)
        n = name.to_s

        if n == "auto"
          n = autoscm
        end

        if n.nil? || n.blank?
          if options[:required]
            raise "could not automatically determine SCM"
          else
            return
          end
        end

        require "volley/scm/#{n}"
        klass = "Volley::Scm::#{n.camelize}".constantize
        @source = klass.new(options)
      rescue => e
        raise "unable to load SCM provider: #{n} #{e.message}"
      end

      def source
        @source or raise "SCM not configured"
      end

      #def encrypt(tf, o={})
      #  options = {
      #      :enabled => tf,
      #      :overwrite => false,
      #      :key => "",
      #  }.merge(o)
      #  config.encrypt = OpenStruct.new(options)
      #
      #  key = config.encrypt.key
      #  if File.file?(key)
      #    key = File.read(key).chomp
      #  end
      #
      #  config.encrypt.key = key
      #end
      #
      #def pack(tf, o={})
      #  options = {
      #      :enabled => tf,
      #      :type => "tgz",
      #  }.merge(o)
      #  config.pack = OpenStruct.new(options)
      #end

      private

      def autoscm
        return "git" if File.directory?(File.expand_path("./.git"))
        return "subversion" if File.directory?(File.expand_path("./.svn"))
        nil
      end
    end
  end
end
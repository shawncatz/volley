
module Volley
  module Dsl
    class Project
      class << self
        attr_reader :projects
        def project(name, o={}, &block)
          n = name.to_sym
          @projects ||= {}
          if @projects[n]
            #raise "defining project #{name} more than once"
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
      end

      attr_reader :plans
      attr_reader :name
      attr_reader :source

      def initialize(name)
        @name = name
        @plans = {}
      end

      def config
        @config ||= OpenStruct.new
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
        n = name.to_s
        require "volley/scm/#{n}"
        klass = "Volley::Scm::#{n.camelize}".constantize
        @source = klass.new(o)
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
    end
  end
end
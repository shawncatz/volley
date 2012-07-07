
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
      end

      attr_reader :plans
      attr_reader :name
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
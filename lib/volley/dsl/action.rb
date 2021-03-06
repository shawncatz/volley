
module Volley
  module Dsl
    class Action
      attr_reader :plan

      delegate :project, :args, :files, :file, :attributes, :log, :arguments, :argv, :branch, :version, :action, :volley, :stop, :source,
               :to => :plan

      def initialize(name, options={}, &block)
        @name = name.to_sym
        @stage = options.delete(:stage)
        @plan = options.delete(:plan)
        @block = block
        @options = {
        }.merge(options)
        raise "stage instance must be set" unless @stage
        raise "plan instance must be set" unless @plan
      end

      def call
        return if @plan.stopped?
        Volley::Log.debug "## #{project.name}:#{@plan.name}[#{@stage}]##@name"
        self.instance_eval &@block if @block
      end

      def command(cmd)
        plan.shellout(cmd)
      end
    end
  end
end
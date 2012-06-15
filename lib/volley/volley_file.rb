
module Volley
  module VolleyFile
    class << self
      def load(filename, options={})
        @plans ||= {}
        file = File.expand_path(filename)

        if File.file?(file)
          instance_eval(File.read(file), "Volleyfile") if File.file?(file)
        else
          raise "cannot read file" unless options[:optional]
        end
      end

      def run(name, opts={})
        n = name.to_sym
        raise "plan #{n} not found" unless @plans && @plans[n]
        data = @plans[n]
        plan = data[:class].new(n, opts)
        plan.instance_eval &data[:block]
        plan.run
      end

      # Volleyfile top-level DSL methods

      def plan(name, klass=Volley::Plan::Base, &block)
        n = name.to_sym
        raise "plan name #{n} is already used" if @plans[n]
        @plans[n] = {:name => name, :class => klass, :block => block}
      end

      def project(name)
        config.project = name
      end

      def config
        Volley.config
      end
    end
  end
end
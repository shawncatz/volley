
module Volley
  module VolleyFile
    class << self
      def load(filename, options={})
        @projects ||= {}
        @plans ||= {}
        file = File.expand_path(filename)

        if File.file?(file)
          instance_eval(File.read(file), "Volleyfile")
        else
          raise "cannot read file" unless options[:optional]
        end
        config.volleyfile = "#{Dir.pwd}/Volleyfile" if options[:primary]
      end

      def run(project, name, opts={})
        n = name.to_sym
        raise "plan #{n} for project #{project} not found" unless @projects[project] && @projects[project][n]
        data = @projects[project][n]
        #ap @projects
        plan = data[:class].new(n, opts.merge(:project => project))
        plan.instance_eval &data[:block]
        plan.run
      end

      # Volleyfile top-level DSL methods
      def plan(name, klass=Volley::Plan::Base, &block)
        n = name.to_sym
        raise "plan name #{n} is already used" if @plans[n]
        @projects[@project][n] = {:name => name, :class => klass, :block => block}
      end

      def project(name)
        @projects[name] ||= {}
        @project = name
        if block_given?
          yield
        end
        @project = nil
      end

      def config
        Volley.config
      end
    end
  end
end
#require "awesome_print"
require "ostruct"
require "active_support/all"

require "volley/version"
require "volley/config"
require "volley/log"
require "volley/publisher/base"
require "volley/publisher/exceptions"
require "volley/descriptor"
require "volley/meta"

require "volley/dsl"

module Volley
  class << self
    def process(opts)
      project = nil
      plan    = opts[:plan]
      args    = opts[:args] || []
      desc    = opts[:descriptor]
      second  = opts[:second]

      (project, plan) = plan.split(/:/) if plan =~ /\:/
      (project, _, _) = Volley::Descriptor.new(desc).get unless project

      begin
        Volley::Log.debug "PROCESS plan:#{plan} descriptor:#{desc} args:#{args}"
        if Volley::Dsl.project?(project)
          # we have the project locally
          pr = Volley::Dsl.project(project)
          if pr.plan?(plan)
            # plan is defined
            pl = pr.plan(plan)
            #args << "branch:#{branch}" if branch && args.select{|e| e =~ /^branch\:/}.count == 0
            #args << "version:#{version}" if version && args.select{|e| e =~ /^version\:/}.count == 0
            args << "descriptor=#{desc}"
            data = pl.call(:args => args)

            if plan == "deploy"
              Volley.meta[project] = data
            end
            Volley.meta.save
          else
            # plan is not defined
            raise "could not find plan #{plan} in project #{project}"
          end
        else
          raise "second loop, downloaded volleyfile failed?" if second
          # we dont have the project locally, search the publisher
          pub = Volley::Dsl.publisher
          if pub
            if pub.projects.include?(project)
              vf = pub.volleyfile(opts)
              Volley::Log.debug "downloaded volleyfile: #{vf}"
              Volley::Dsl::VolleyFile.load(vf)
              process(:project => project, :plan => plan, :branch => branch, :version => version, :args => args, :second => true)
            else
              raise "project #{project} does not exist in configured publisher #{pub.class}"
            end
          else
            raise "project #{project} does not exist locally, and no publisher is configured."
          end
        end
      rescue => e
        Volley::Log.error "error while processing: #{e.message}"
        Volley::Log.debug e
        raise e
      end

      #if Volley.config.debug
      #  ap Volley::Dsl::Project.project
      #end
    end
  end
end

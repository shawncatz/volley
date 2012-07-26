#require "awesome_print"
require "ostruct"
require "active_support/all"

require "volley/version"
require "volley/config"
require "volley/log"
require "volley/volley_file"
require "volley/publisher/base"

require "volley/dsl"

module Volley
  class << self
    def process(opts)
      project = opts[:project]
      plan    = opts[:plan]
      branch  = opts[:branch]
      version = opts[:version]
      args    = opts[:args]
      second  = opts[:second]

      begin
        Volley::Log.debug "PROCESS project:#{project} plan:#{plan} branch:#{branch} version:#{version} args:#{args}"
        if Volley::Dsl.project?(project)
          # we have the project locally
          pr = Volley::Dsl.project(project)
          if pr.plan?(plan)
            # plan is defined
            pl = pr.plan(plan)
            args << "branch:#{branch}" if branch && args.select{|e| e =~ /^branch\:/}.count == 0
            args << "version:#{version}" if version && args.select{|e| e =~ /^version\:/}.count == 0
            pl.call(:rawargs => args)
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
              Volley::VolleyFile.load(vf)
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
      end

      #if Volley.config.debug
      #  ap Volley::Dsl::Project.projects
      #end
    end
  end
end

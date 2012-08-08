#require "awesome_print"
require "ostruct"
require "active_support/all"

require "volley/version"
require "volley/log"
require "volley/publisher/base"
require "volley/publisher/exceptions"
require "volley/descriptor"
require "volley/meta"

require "volley/dsl"

module Volley
  class << self
    def config
      @config ||= OpenStruct.new({:directory => "/opt/volley"})
    end

    def meta
      @meta ||= Volley::Meta.new
    end

    def unload
      Volley::Log.debug "Unload"
      @config = nil
      @meta = nil
      Volley::Dsl::VolleyFile.unload
      Volley::Dsl::Project.unload
    end

    def process(plan, desc, args)
      second   = args.delete(:second)

      (runpr, plan) = plan.split(/:/) if plan =~ /\:/
      (project, branch, version) = Volley::Descriptor.new(desc).get rescue [nil,nil,nil]
      runpr ||= project

      begin
        if Volley::Dsl.project?(runpr)
          # we have the project locally
          pr = Volley::Dsl.project(runpr)

          if pr.plan?(plan)
            # plan is defined

            if plan == "deploy" && Volley.meta.check(project, branch, version) && !args[:force]
              raise "project #{project} is already #{branch}:#{version}"
            end

            args[:descriptor] = desc
            data = pr.plan(plan).call(:args => args)

            if plan == "deploy"
              Volley.meta[project] = data
              Volley::Log.debug "== #{runpr} = #{data}"
            end
            Volley.meta.save
          else
            # plan is not defined
            raise "could not find plan #{plan} in project #{project}"
          end
        else
          # we dont have the project locally, search the publisher
          raise "second loop, downloaded volleyfile failed?" if second

          pub = Volley::Dsl.publisher
          if pub
            if pub.projects.include?(project) && branch
              vf = pub.volleyfile(project, branch, version)
              version = pub.latest_version(project, branch) if version.nil? || version == "latest"

              Volley::Log.debug "downloaded volleyfile: #{vf}"
              Volley::Dsl::VolleyFile.load(vf)
              args[:second] = true
              process("#{project}:#{plan}", desc.to_s, args)
            else
              raise "project #{project} does not exist in configured publisher #{pub.class}"
            end
          else
            raise "project #{project} does not exist locally, and no publisher is configured."
          end
        end
      rescue => e
        #Volley::Log.error "error while processing: #{e.message}"
        #Volley::Log.debug e
        raise e
      end
    end
  end
end

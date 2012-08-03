
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
  end
end
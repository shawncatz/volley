
module Volley
  class << self
    def config
      @config ||= OpenStruct.new({:directory => "/opt/volley"})
    end

    def meta
      @meta ||= Volley::Meta.new
    end
  end
end
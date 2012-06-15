
module Volley
  class << self
    def config
      @config ||= OpenStruct.new({})
    end
  end
end
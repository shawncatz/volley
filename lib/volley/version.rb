unless defined?(Volley::Version)
  module Volley
    module Version
      MAJOR  = 0
      MINOR  = 1
      TINY   = 0
      TAG    = "alpha11"
      STRING = [MAJOR, MINOR, TINY, TAG].compact.join('.')
    end
  end
end
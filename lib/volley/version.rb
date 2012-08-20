unless defined?(Volley::Version)
  module Volley
    module Version
      MAJOR  = 0
      MINOR  = 1
      TINY   = 1
      TAG    = nil
      STRING = [MAJOR, MINOR, TINY, TAG].compact.join('.')
    end
  end
end
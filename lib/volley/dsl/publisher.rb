
module Volley
  module Dsl
    class Publisher
      class << self
        def publisher(name, o={}, &block)
          n = name.to_sym

          if @publisher
            raise "only one publisher can be defined at a time"
          else
            klass = "Volley::Publisher::#{name.to_s.camelize}"
            Volley::Log.info "loading publisher: #{name} (#{klass})" if Volley.config.debug
            require "volley/publisher/#{name}"
            @publisher = klass.constantize.new(o)
          end
        end

        def get
          @publisher
        end
      end
    end
  end
end
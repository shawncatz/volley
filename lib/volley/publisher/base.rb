
module Volley
  module Publisher
    class Base
      def initialize(options={})
        @options = {}.merge(options)
        load_configuration
      end

      def config(name)
        v = get_option(name) || get_config(name)
        raise "Publisher #{me} requires configuration #{name}" if v.nil?
        v
      end

      def requires(name)
        v = get_option(name)
        raise "Publisher #{me} requires option #{name}" if v.nil?
        v
      end

      def optional(name)
        get_option(name)
      end

      private
      def me
        self.class.name.split("::").last
      end

      def get_option(name)
        n = name.to_sym
        @options[n]
      end

      def get_config(name)
        n = name.to_sym
        Volley.config.send(n)
      end
    end
  end
end
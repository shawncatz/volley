module Yell
  module Adapters
    class Volley < Yell::Adapters::Datefile
      # @overload open!
      def open!
        @stream = ::File.open( @filename, ::File::WRONLY|::File::APPEND|::File::CREAT, 0664 )

        super
      end
    end
    register( :volley, Yell::Adapters::Volley )
  end
end

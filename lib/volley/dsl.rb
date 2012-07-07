d = "#{File.dirname(__FILE__)}/dsl/*"
Dir[d].select{|e| e =~ /\.rb$/}.each do |file|
  f = file.gsub(/\.rb$/, '')
  require f
end

module Volley
  module Dsl
    class << self
      def publisher
        Volley::Dsl::Publisher.get
      end

      def project(name)
        Volley::Dsl::Project.get(name)
      end
    end
  end
end
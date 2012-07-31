
module Volley
  class Meta
    def initialize
      @file = "#{Volley.config.directory}/meta.yaml"
      @data = YAML.load_file(@file) if File.file?(@file)
      @data ||= {}
    end

    def [](project)
      @data[project.to_sym]
    end

    def []=(project, version)
      @data[project.to_sym] = version
    end

    def save
      File.open(@file, "w") {|f| f.write(@data.to_yaml)}
    end
  end
end
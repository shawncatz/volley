
module Volley
  class Meta
    def initialize(file="#{Volley.config.directory}/meta.yaml")
      @file = file
      dir = File.dirname(file)
      unless File.directory?(dir)
        Volley::Log.warn "meta file directory does not exist: #{dir}"
        FileUtils.mkdir_p(dir)
      end
      @data = YAML.load_file(@file) || {} rescue {}
    end

    def [](project)
      @data[:projects] ||= {}
      @data[:projects][project.to_sym]
    end

    def []=(project, version)
      @data[:projects] ||= {}
      @data[:projects][project.to_sym] = version
    end

    def save
      @data[:volley] ||= {}
      @data[:volley][:version] = Volley::Version::STRING
      File.open(@file, "w+") {|f| f.write(@data.to_yaml)}
    end

    def check(project, branch, version)
      version = Volley::Dsl.publisher.latest_version(project, branch) if version.nil? || version == 'latest'
      self[project] == "#{branch}:#{version}"
    end

    def projects
      @data[:projects]
    end
  end
end
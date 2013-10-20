module StaticMatic
  class Base

    include StaticMatic::RenderMixin
    include StaticMatic::BuildMixin
    include StaticMatic::SetupMixin
    include StaticMatic::HelpersMixin
    include StaticMatic::ServerMixin
    include StaticMatic::RescueMixin

    attr_accessor :configuration, :mode
    attr_reader :src_dir, :site_dir

    def current_file
      @current_file_stack[0] || ""
    end

    def self.extensions
      @extensions ||= (Tilt.mappings.map { |k,v| k } << "slim")
    end

    def extensions
      self.class.extensions
    end

    def ensure_extension(filename)
      ext = File.extname(filename)
      ext.length > 0 ? filename : "#{filename}.#{configuration.default_template_engine}"
    end

    def initialize(base_dir, mode = :preview)
      @configuration = Configuration.new
      @current_file_stack = []
      @mode = mode

      @default_layout_name = "default"

      @scope = Object.new
      @scope.instance_variable_set("@staticmatic", self)
      @scope.instance_eval do
        extend StaticMatic::Helpers
      end

      load_configuration

      @base_dir = base_dir
      @src_dir = File.join(@base_dir, @configuration.site_dir)
      @site_dir = File.join(@base_dir, @configuration.build_dir)

      configure_compass
      load_helpers
    end

    def load_configuration
      configuration = StaticMatic::Configuration.new
      config_file = File.join(@base_dir, "config", "site.rb")

      if File.exists?(config_file)
        config = File.read(config_file)
        eval(config)
      end

      @configuration = configuration
    end

    def base_dir
      @base_dir
    end

    def run(command)
      puts "Site root is: #{@base_dir}"

      if %w(build setup preview).include?(command)
        send(command)
      else
        puts "#{command} is not a valid StaticMatic command"
      end
    end

    def determine_template_path(name, ext, dir = '')
      # remove src path if present
      dir.gsub! /^#{@src_dir}\//, ''

      default_template_name = "#{name}.#{configuration.default_template_engine}"
      default_template = File.join(@src_dir, dir, default_template_name)

      if File.exists? default_template
        default_template
      else
        context = File.join(@src_dir, dir, name)
        possible_templates = Dir[context + '.*'].select do |fname|
          extensions.include? File.extname(fname).sub(/^\./, '')
        end

        if possible_templates.count > 1
          raise StaticMatic::AmbiguousTemplateError.new("#{name}#{ext}", possible_templates)
        end

        possible_templates.first
      end
    end

    def expand_path(path_info)
      dirname, basename = File.split(path_info)

      extname = File.extname(path_info).sub(/^\./, '')
      filename = basename.chomp(".#{extname}")

      if extname.empty?
        dir = File.join(dirname, filename)
        is_dir = path_info[-1, 1] == '/'
        if is_dir
          dirname = dir
          filename = 'index'
        end
        extname = 'html'
      end

      [ dirname, filename, extname ]
    end

    def configure_compass
      Compass.configuration.project_path = @base_dir

      compass_config_path = File.join(@base_dir, "config", "compass.rb")

      if File.exists?(compass_config_path)
        Compass.add_configuration(compass_config_path)
      end

      options = configuration.engine_options
      compass_options = Compass.configuration.to_sass_engine_options

      options['sass'] = compass_options.merge(options['sass'] || {})
      options['scss'] = compass_options.merge(options['scss'] || {})
    end

    # TODO OPTIMIZE: caching, maybe?
    def src_file_paths(*exts)
      Dir["#{@src_dir}/**/*.{#{ exts.join(',') }}"].reject do |path|
        # reject any files with a prefixed underscore, as
        # well as any files in a folder with a prefixed underscore
        path.split('/').map {|x| x.match('^\_')}.any?
      end
    end

  end
end

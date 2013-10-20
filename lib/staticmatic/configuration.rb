module StaticMatic
  class Configuration
    attr_accessor :preview_server
    attr_accessor :preview_server_host
    attr_accessor :preview_server_port
    attr_accessor :ssl_enable
    attr_accessor :ssl_private_key_path
    attr_accessor :ssl_certificate_path

    attr_accessor :site_dir
    attr_accessor :build_dir

    attr_accessor :use_extensions_for_page_links
    attr_accessor :default_template_engine

    attr_accessor :engine_options, :preview_engine_options
    attr_accessor :reverse_ext_mappings

    def initialize
      self.preview_server = Rack::Handler::WEBrick
      self.preview_server_host = "localhost"
      self.preview_server_port = 4000

      self.use_extensions_for_page_links = true
      self.default_template_engine = 'haml'

      self.site_dir = 'src'
      self.build_dir = 'build'

      self.engine_options = {
        'haml' => {}, 'sass' => {}, 'scss' => {},
      }
      self.preview_engine_options = self.engine_options.clone

      # TODO: discover a way of auto-detecting these. one can hope.
      self.reverse_ext_mappings = {
        'sass' => 'css',
        'scss' => 'css',
        'less' => 'css',

        'coffee' => 'js',

        'builder' => 'xml',
        'yajl' => 'json'
      }

      %w{
        creole erb haml liquid radius mab markdown md
        mediawiki mkd mw nokogiri rdoc rhtml slim textile wiki
      }.each do |ext|
        @reverse_ext_mappings[ext] = 'html'
      end
    end

  end
end

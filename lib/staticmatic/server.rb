module StaticMatic
  class Server
    def initialize(staticmatic, default = nil)
      @files = default || Rack::File.new(staticmatic.src_dir)
      @staticmatic = staticmatic
    end

    def call(env)
      @staticmatic.load_helpers
      path_info = env["PATH_INFO"]

      file_dir, file_name, file_ext = @staticmatic.expand_path(path_info)
      
      file_dir = CGI::unescape(file_dir)
      file_name = CGI::unescape(file_name)

      unless file_ext && ["html", "css", "js"].include?(file_ext) &&
          File.basename(file_name) !~ /^\_/ &&
          (template_path = @staticmatic.determine_template_path file_name, file_ext, file_dir)
        return @files.call(env)
      end

      res = Rack::Response.new

      begin
        @staticmatic.clear_template_variables!

        if file_ext == "css"
          res.header["Content-Type"] = "text/css"
          res.write @staticmatic.render_template(template_path)
        elsif file_ext == "js"
          res.header["Content-Type"] = "text/javascript"
          res.write @staticmatic.render_template(template_path)
        else
          res.header["Content-Type"] = "text/html"
          res.write @staticmatic.render_template_with_layout(template_path)
        end
      rescue StaticMatic::Error => e
        res.write e.message
      end

      res.finish
    end

    # Starts the StaticMatic preview server
    def self.start(staticmatic)
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap(signal) do
          puts 
          puts "Exiting"
          exit!(0)
        end
      end
      port = staticmatic.configuration.preview_server_port || 3000

      host = staticmatic.configuration.preview_server_host || ""

      app = Rack::Builder.new do
        use Rack::ShowExceptions
        run StaticMatic::Server.new(staticmatic)
      end 

      ssl_enable = staticmatic.configuration.ssl_enable || false

      if not ssl_enable
        staticmatic.configuration.preview_server.run(app, :Port => port, :Host => host)
      else
        ssl_verify_client = OpenSSL::SSL::VERIFY_NONE
        ssl_private_key = OpenSSL::PKey::RSA.new(File.open(staticmatic.configuration.ssl_private_key_path).read)
        ssl_certificate = OpenSSL::X509::Certificate.new(File.open(staticmatic.configuration.ssl_certificate_path).read)
        ssl_cert_name = [["CN", WEBrick::Utils::getservername]]
        staticmatic.configuration.preview_server.run(
          app, 
          :Port => port, 
          :Host => host,
          :SSLEnable => true,
          :SSLPrivateKey => ssl_private_key,
          :SSLCertificate => ssl_certificate,
          :SSLCertName => ssl_cert_name
        )

      end
      
    end

  end
end

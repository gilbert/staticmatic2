module StaticMatic
  module Helpers
    module AssetsHelper
      self.extend self
      
      # Generates links to all stylesheets in the source directory
      # = stylesheets
      # or specific stylesheets in a specific order
      # = stylesheets :reset, :application
      # Can also pass options hash in at the end so you can specify :media => :print
      def stylesheets(*params)
        options = (params.last.is_a? Hash) ? params.pop : {}
        
        options[:media] = 'all' unless options.has_key?(:media)
        options[:rel] = 'stylesheet'; options[:type] = 'text/css'

        src_files = @staticmatic.src_file_paths('sass','scss','css')
        output = ""

        if params.length == 0
          # no specified files; include them all!
          src_files.each {|path| output << format_output(:link,path,options) }
        else
          # specific files requested and in a specific order
          params.each do |file|

            if file.to_s.match %r{^https?://}
              output << format_output(:link,file,options)
            else
              idx = src_files.index do |src|
                %w{sass scss css}.map {|t| src.match /#{file}\.#{t}$/ }.any?
              end
              output << format_output(:link,src_files[idx],options) unless idx.nil?
            end
          end
        end
        output
      end
      
      # Generate javascript source tags for the specified files
      #
      # javascripts('test')   ->   <script language="javascript" src="path/to/test.js"></script>
      #    
      def javascripts(*files)
        options = (files.last.is_a? Hash) ? files.pop : {}
        
        options[:language] = 'javascript'
        options[:type] = 'text/javascript'
        
        src_files = @staticmatic.src_file_paths('js','coffee')
        output = ""

        files.each do |path|
          if path.to_s.match %r{^https?://}
            output << format_output(:script,path,options)
          else
            idx = src_files.index do |src|
              %w{coffee js}.map {|t| src.match /#{path.to_s}\.#{t}$/ }.any?
            end
            output << format_output(:script,src_files[idx],options) unless idx.nil?
          end
        end
        output
      end

      # Generates an image tag always relative to the current page unless absolute path or http url specified.
      # 
      # img('test_image.gif')   ->   <img src="/images/test_image.gif" alt="Test image"/>
      # img('contact/test_image.gif')   ->   <img src="/images/contact/test_image.gif" alt="Test image"/>
      # img('http://localhost/test_image.gif')   ->   <img src="http://localhost/test_image.gif" alt="Test image"/>
      def img(name, options = {})
        options[:src] = name.match(%r{^((\.\.?)?/|https?://)}) ? name : "#{current_page_relative_path}images/#{name}"
        options[:alt] ||= name.split('/').last.split('.').first.capitalize.gsub(/_|-/, ' ')
        tag :img, options
      end
      
      def format_output(tag_type,path,options)
        external_url = !!path.match(%r{^https?://})

        if external_url
          src = path
        else
          filename_without_extension = File.basename(path).chomp(File.extname(path))
      
          path = path.gsub(/^#{@staticmatic.src_dir}/, "").
                     gsub(/^#{@staticmatic.site_dir}/, "").
                     gsub(/#{filename_without_extension}\.(sass|scss|css|js|coffee)/, "").
                     gsub(/^\//, "")
          paths = [current_page_relative_path, path, "#{filename_without_extension}"].compact
          src = File.join(*paths)
        end
        
        if tag_type == :link
          src += '.css' if !external_url
          options[:href] = qstring(src, options[:qstring]); options.delete :qstring
          tag(tag_type,options)
        elsif tag_type == :script
          src += '.js' if !external_url
          options[:src] = qstring(src, options[:qstring]); options.delete :qstring
          tag(tag_type,options) { '' }
        end
        
      end
      
      # Prepares a query string based on the given qstr.
      # If qstr is true, it generates a query string based on the current time.
      # If qstr is a string, it uses it as the query string itself.
      # 
      def qstring(src,qstr)
        src += '?_=' + Time.now.to_i.to_s if qstr == true
        src += '?_=' + qstr if qstr.is_a? String
        src
      end
    end
  end
end

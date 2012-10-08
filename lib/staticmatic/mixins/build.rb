module StaticMatic::BuildMixin
    
  def build
    src_file_paths('*').each do |src_path|
      ext = File.extname(src_path).sub(/^\./, '')

      if Tilt.mappings[ext].length > 0
        generate_site_file(src_path)
      else
        copy_file_from_src_to_site(src_path)
      end
    end
  end

  private

  def copy_file_from_src_to_site(src_path)
    site_path = src_path.gsub /^#{@src_dir}/, @site_dir

    FileUtils.mkdir_p(File.dirname site_path)
    FileUtils.cp_r src_path, site_path
  end

  def generate_site_file(src_path)
    dir, name, ext = expand_path(src_path.gsub /^#{@src_dir}/, @site_dir)
    target_ext = configuration.reverse_ext_mappings[ext]
    site_path = File.join(dir, "#{name}.#{target_ext}")

    puts "  Rendered #{src_path} => #{site_path}"

    FileUtils.mkdir_p(File.dirname site_path)
    File.open(site_path, 'w+') do |f|
      if target_ext == 'html'
        f << render_template_with_layout(src_path)
      else
        f << render_template(src_path)
      end
    end
  end

end

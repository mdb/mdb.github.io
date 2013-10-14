module TemplateHelpers
  def blog_thumb_path file_name
    image_path("blog/thumbnails/#{file_name}")
  end

  def project_thumb_path file_name
    image_path("projects/thumbnails/#{file_name}")
  end
end

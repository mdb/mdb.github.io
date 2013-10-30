module TemplateHelpers
  def last_class array, index
    if index + 1 == array.length
      "last"
    else
      ""
    end
  end

  def blog_thumb_path file_name
    image_path("blog/thumbnails/#{file_name}")
  end

  def project_thumb_path file_name
    image_path("projects/thumbnails/#{file_name}")
  end
end

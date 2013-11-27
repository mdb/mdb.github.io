module TemplateHelpers
  # Temporary workaround for this issue:
  # https://github.com/middleman/middleman-blog/issues/145
  def tag_url_path path_prefix, tag
    "/#{path_prefix}/tags/#{tag.gsub(/ /, '-')}"
  end

  def first_or_last_class array, index
    if array.length == 1
      "first last"
    elsif index == 0
      "first"
    elsif index + 1 == array.length
      "last"
    else
      ""
    end
  end

  def default_thumb_path
    image_path("blog/thumbnails/default_thumb.gif")
  end

  def blog_thumb_path file_name
    if file_name.nil?
      default_thumb_path
    else
      image_path("blog/thumbnails/#{file_name}")
    end
  end

  def project_thumb_path file_name
    if file_name.nil?
      default_thumb_path
    else
      image_path("projects/thumbnails/#{file_name}")
    end
  end

  def all_posts
    blog_posts.concat(project_posts).sort_by{ |post| post.date }.reverse
  end

  def blog_posts
    blog('blog').articles
  end

  def project_posts
    blog('projects').articles
  end

  def is_blog_post(item)
    post_type(item) == 'blog'
  end

  def is_project_post(item)
    post_type(item) == 'projects'
  end

  def post_type(item)
    if item.path.include? 'projects'
      'projects'
    elsif item.path.include? 'blog'
      'blog'
    else
      'blog'
    end
  end
end

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

  def gallery_item_classes(display_teaser = false)
    if display_teaser
      "item teaser"
    else
      "item"
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

  def blog_posts(options = {})
    fetch_posts('blog', options)
  end

  def project_posts(options = {})
    fetch_posts('projects', options)
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

  # private-by-convention helper
  def fetch_posts(type, options)
    opts = {
      exclude: nil,
      limit: nil,
      only_featured: false
    }.merge(options)

    posts = blog(type).articles.reject { |post| post == opts[:exclude] }

    if options[:only_featured]
      posts = posts.reject { |post| post.data.featured != true }
    end

    if opts[:limit].nil?
      posts
    else
      posts.first(opts[:limit])
    end
  end

  def slideshow_input(index)
    checked = index == 0 ? 'checked' : ''

    "<input type='radio', id='slide-#{index+1}', name='slide' #{checked} />"
  end
end

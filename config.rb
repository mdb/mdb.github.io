require 'redcarpet'
require 'lib/template_helpers'
require 'fog'

helpers TemplateHelpers

set :markdown,
  tables: true,
  autolink: true,
  gh_blockcode: true,
  fenced_code_blocks: true,
  with_toc_data: true
set :markdown_engine, :redcarpet
set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :haml, { ugly: true }

set :site_title, 'Mike Ball'
set :url, 'http://www.mikeball.info'
set :description, 'Recent projects, blog, and information'

# Blog
activate :blog do |blog|
  blog.name = "blog"
  blog.prefix = "blog"
  blog.permalink = ":title.html"
  blog.tag_template  = "tag_blog.html"
end

page "blog/*", layout: :article
page "blog", layout: :layout
page "blog/tags/*", layout: :layout

# Portfolio
activate :blog do |blog|
  blog.name = "projects"
  blog.prefix = "projects"
  blog.permalink = ":title.html"
  blog.tag_template  = "tag_projects.html"
end

page "projects/*", layout: :project
page "projects", layout: :layout
page "projects/tags/*", layout: :layout
page "/atom.xml", layout: false
page "/rss.xml", layout: false
page "/posts.json", layout: false
page "/404.html"

activate :directory_indexes
activate :syntax, line_numbers: true
activate :build_reporter

# Add bower_components directory to asset pipeline
sprockets.append_path File.join "#{root}", "bower_components"

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
  activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

# Make middleman-sync work with AWS bucket name containing dots
# https://github.com/karlfreeman/middleman-sync/issues/29
Fog.credentials = { path_style: true }

# Deployment
activate :sync do |sync|
  sync.fog_provider = 'AWS'
  sync.fog_directory = 'www.mikeball.info'
  sync.fog_region = 'us-east-1'
  sync.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  sync.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  sync.existing_remote_files = 'delete'
  # sync.gzip_compression = false # Automatically replace files with their equivalent gzip compressed version
  # sync.after_build = false # Disable sync to run after Middleman build ( defaults to true )
end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Blog
activate :blog do |blog|
  blog.name = "blog"
  blog.prefix = "blog"
  blog.tag_template  = "tag.html"
end

page "blog/*", :layout => :article
page "blog", :layout => :layout
page "blog/tags/*", :layout => :layout

# Portfolio
activate :blog do |blog|
  blog.name = "projects"
  blog.prefix = "projects"
  blog.permalink = ":title.html"
  blog.tag_template  = "tag.html"
end

page "projects/*", :layout => :project
page "projects", :layout => :layout
page "projects/tags/*", :layout => :layout

activate :directory_indexes

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

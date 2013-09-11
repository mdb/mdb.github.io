source 'https://rubygems.org'

ruby "2.0.0"

gem 'rails', '4.0.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'

# Only seems to work when required outside of
# :assets group
gem 'asset_sync'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  # Use Uglifier as compressor for JavaScript assets
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'acts-as-taggable-on', '2.4.1'
gem 'paperclip', '3.4.2'
gem 'aws-sdk'
gem 'git'

# Gems only required when building
group :build do
  gem 'archive-tar-minitar'
end

group :test, :development do
  gem "rspec-rails"
  gem "capybara"
  gem "guard-rspec"
  gem "growl_notify"
  gem "minitest"
  gem "pry"
  gem 'heroku_san'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Heroku
gem 'rails_12factor', group: :production

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

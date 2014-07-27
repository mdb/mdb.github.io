---
published: false
---

# Using Teaspoon to Test JavaScript in a Rails Application

Through HTML5 &mdash; and the development of new browser APIs &mdash; more and
more web applications serve a large JavaScript layer. Historically, the Ruby on
Rails community has been adament in its advocacy of automated testing; numerous
tools such as Rspec, Minitest, FactoryGirl, and VCR seek to assist developers in
ensuring Ruby code quality via a healthy suite of automated tests. Yet, with the
advent of more JavaScript-intensive applications such as those built on Angular,
Backbone, and Ember, a larger degree of functionality and business logic lives
on the clientside where it's executed in the user's browser rather than a
Ruby-powered back end. In the case of these JavaScript-heavy applications, how
can developers ensure their applications feature full test coverage through all
layers of the software, including the JavaScript front end? Tools such as
Jasmine, Mocha, and and Karma help, but what's the best way to integrate these
technologies with a Ruby on Rails project? Teaspoon is a full-featured
JavaScript test runner built specifically for Rails; it respects the Rails asset
pipeline, can be run headlessly in continuous integration, and supports code
coverage analysis.

In this tutorial, we'll walk through setting up a simple Ruby on Rails-based
Backbone.js application using Teaspoon as its test runner, Jasmine as its
testing framework, and istanbul as its code coverage analyzer.

What we'll cover:

1. Setting up Ruby on Rails
2. Installing Teaspoon
3. Configuring Teaspoon
4. Writing your first test
5. Automating your tests in continuous integration
6. Configuring code coverage analysis

## Setting up Rails

For this excercise, I'm using Mac OS 10.9.4, Ruby 2.0.0p454, and Rails 4.1.4. I am assuming some
basic familiarity with the Mac OS command line.

Open a terminal and install Rails:

```
$ gem install rails
```

Generate a new Rails project called `teaspoon-demo` and enter its directory:

```
$ rails new teaspoon-demo && cd teaspoon-demo
```

Confirm your Rails app is working.

Run the server:

```
$ rails s
```

Visit http://localhost:3000 in your web browser and confirm that the app
resolves.

## Disable coffeescript

[coffeescript]() is a great tool that assists in some common
JavaScript-authoring pain points, though it's a bit beyond the scope of this
tutorial.

Disable coffeescript by removing the following line from your
`teaspoon-demo/Gemfile`:

```ruby
gem 'coffee-rails', '~> 4.0.0'
```

TODO: include note about re-bundle installing and re-generating Gemfile.lock?

## Install Underscore & Backbone

[RubyGems](https://rubygems.org) addresses Ruby package and dependency management, but what
about JavaScript dependencies? [Bower](http://bower.io/) is front end package
manager; [Rails Assets](https://rails-assets.org/) re-packages Bower components
as Ruby gems and exposes them to the Rails asset pipeline. Let's use Rails
Assets to install Backbone.

Add `https://rails-assets.org` as a new gem source by adding the following to
line 2 of your `teaspoon-demo/Gemfile`:

```ruby
source 'https://rails-assets.org'
```

Add Backbone as a Rails Assets teaspoon-demo dependency by adding the following to your
`teaspoon-demo/Gemfile`:

```ruby
gem 'rails-assets-backbone'
```

Install your new `rails-assets-backbone` gem dependency:

```
$ bundle install
```

## Installing teaspoon

Add teaspoon v0.8.0 as a teaspoon-demo dependency by adding the following to `teaspoon-demo/Gemfile`:

```ruby
gem 'teaspoon', '0.8.0'
```

Install your gem dependencies, including the now-added teaspoon:

```
bundle install
```

## Setting up a basic index view

Let's set up a basic homepage for teaspoon-demo.

```
rails generate controller home index
```

Ensure Backbone is served by editing our



## Setting Up Rails

For this excercise, I'm using Mac OS 10.9.4, Ruby 2.0.0p454, and Rails 4.1.4. I'm assuming some
basic familiarity with Rails and the Mac OS command line.

I've created a basic teaspoon-demo Rails project and pushed the repo to GitHub.
Clone the repo, enter the teaspoon-demo directory, and install its Ruby gem
dependencies:

```
$ git clone https://github.com/mdb/teaspoon-demo && cd teaspoon-demo && bundle
install
```

This is a largely out-of-the-box installation with just a few exceptions:

1. I've removed `'coffee-rails'` from the `teaspoon-demo/Gemfile`. [CoffeeScript]() is a great JavaScript authoring tool, though it's a bit beyond the scope of this
tutorial. We'll be using plain JavaScript.

2. `teaspooon` v0.8.0 has been added to the Gemfile.

3. `source 'https://rails-assets.org` has been added to line 2 of the Gemfile.
[RubyGems](https://rubygems.org) addresses Ruby package and dependency management, but what
about JavaScript dependencies? [Bower](http://bower.io/) is a frontend package
manager; [Rails Assets](https://rails-assets.org/) re-packages Bower components
as Ruby gems and exposes them to the Rails asset pipeline.

4. `rails-assets-backbone` and `rails-assets-underscore` have been added to the `teaspoon-demo/Gemfile`.
This allows us to use the [Backbone]() and [Underscore]() Bower package as a re-packaged,
asset-pipeline-friendly Ruby gems.

5. `app/assets/javascripts/application.js` requires `underscore` and `backbone`:

6. `app/assets/javascripts/application.js` no longer requires `jquery_ujs` or
   `turbolinks`; neither will be used in teaspoon-demo. I've also removed the
turbolinks-related HTML attributes a default Rails installation passes to
`stylesheet_link_tag` and `javascript_include_tag` in
`app/views/layouts/application.html.erb`.

5. I've added some JavaScript files establishing a very basic Backbone.js
   application:

```
├── application.js
├── collections
│   └── tea_collection.js
├── home.js
├── models
│   └── tea.js
├── templates
│   └── tea_list_item.js
└── views
    ├── tea_list.js
    └── tea_list_item.js
```

6. The above-cited Backbone-related files have been required in the
`application.js` manifest in the proper dependency order.

6. I've set up a basic Rails index URL route in `app/config/routes.rb`, a simple
homepage controller in `app/controllers/home.rb`, and basic view in
`app/views/home/index.html.erb`.

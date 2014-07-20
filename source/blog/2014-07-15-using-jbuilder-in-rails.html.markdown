---
published: false
---

# Building and Testing JSON endpoints in Ruby on Rails with jBuilder

Historically, a conventional Ruby on Rails application leverages server-side business logic, a relational database, and a RESTful CRUD architecture to serve dynamically-generated HTML. However, JavaScript-intensive applications and growing use of external web APIs somewhat challenge this architecture. In many cases a Rails application is tasked in serving as an orchestration layer, collecting data from various backend services and serving reformatted JSON or XML to client applications. In such instances, how is Ruby on Rails' model-view-controller architecture still relevant? In this tutorial, we'll create a simple Rails backend that makes requests to an external XML-based web service, massages its response, and serves JSON. We'll use RSpec, jBuilder, and VCR.

## What are we building?

In this tutorial, we'll create a simple Rails-backed JSON endpoint that renders article search data from the [New York Times API](http://developer.nytimes.com/docs/read/article_search_api_v2).

Why is it necessary to do this if the NY Times API already serves JSON? Fronting the NY Times API with our own JSON endpoint opens a few opportunities:

1. Our app's endpoint could serve JavaScript clients who can't connect across domain names to the NY Times API.
2. Our app's endpoint could reformat NY Times API JSON to better serve its own clients' data formatting preferences.
3. Our app's endpoint is a single interface to the data our clients need, while multiple NY Times API requests are abstracted away by its backend.
4. Our app provides caching opportunities. While it's beyond the scope of this tutorial, our Rails app can cache NY Times API request data, thus offloading NY Times API traffic and avoiding any terms of service or rate limit violations opposed by the NY Times API.

## Set Up

For this tutorial, I am using Mac OS 10.9.4, Ruby 2.1.2, and Rails 4.1.4.

I've created a basic Rails 4 `jbuilder-demo` app. Clone its repo, enter the project directory, and check out its `tutorial` branch:

```
$ git clone http://github.com/mdb/jbuilder-demo && cd jbuilder-demo && git checkout tutorial
```

Install its dependencies:

```
$ bundle install
```

Lets install [RSpec](https://github.com/rspec/rspec-rails) for testing.

Add the following to the project's `Gemfile`:

```
gem 'rspec-rails', '3.0.1'
```

Install `rspec-rails`:

```
$ bundle install
```

We now have an `rspec` generator available to our `rails` command. Let's generate a basic RSpec installation:

```
$ rails generate rspec:install
```

This creates a few new files in a `spec` directory:

```
├── spec
│   ├── rails_helper.rb
│   └── spec_helper.rb
```

The RSpec installation also provides a `spec` rake task. Let's test this:

```
$ rake spec
```

Running `rake spec` generates some basic output like the following, as we haven't yet created any RSpec tests:

```
No examples found.

Finished in 0.00021 seconds (files took 0.0422 seconds to load)
0 examples, 0 failures
```

Note that a default Rails installation assumes tests live in a `tests` directory. RSpec uses a `spec` directory. For clarity's sake, let's delete the `test` directory from `jbuilder-demo`:

```
$ git rm -rf test
```

Commit your changes:

```
$ git add .
$ git commit -m 'created basic RSpec installation'
```

## Let's build a basic route and controller

Generate a controller:

```
$ rails g controller articles_query
```

Note that this created quite a few files, including JavaScript files, stylesheet files, and a helpers module. These are not relevant to our `ArticlesQueryController`; let's undo our controller generation by removing all untracked files from the project. Note that you'll want to commit any changes you do want to preserve.

```
$ git clean -f
```

Now, open `config/application.rb` and add the following generator configuration:

```ruby
config.generators do |g|
  g.helper false
  g.assets false
end
```

Re-running the generate command will now create the desired files:

```
$ rails g controller articles_query
```

Let's add a basic `ArticlesQueryController#index` test to `spec/controllers/articles_query_spec.rb`. The test looks like this:

```ruby
require 'rails_helper'

describe ArticlesQueryController, :type => :controller do
  describe '#index' do
    before :each do
      get :index
    end

    it 'returns success' do
      expect(response).to be_success
    end
  end
end
```

This test currently fails when running `rake spec`, as we haven't yet created a corresponding route.

Let's add the following route to `config/routes.rb`:

```ruby
 match '/query' => 'articles_query#index', via: :get
```

The test still fails when running `rake spec`, now because there isn't a proper `#index` controller action.

Let's create an empty `index` method  in `app/controllers/articles_query_controller.rb`:

```ruby
class ArticlesQueryController < ApplicationController
  def index
  end
end
```

`rake spec` still yields failing tests, this time because we haven't yet created a corresponding view. Let's create a view:

```
$ touch app/views/articles_query/index.json.jbuilder
```

To use this view, we'll need to tweak our ArticlesQueryController a bit. Let's ensure that requests to the `/query` route always returns JSON via a `before_filter` run before each controller action:

```ruby
class ArticlesQueryController < ApplicationController
  before_filter :force_json

  def index
  end

  private

  def force_json
    request.format = :json
  end
end
```

Now, `rake spec` yields passing tests:

```
$ rake spec
.

Finished in 0.0107 seconds (files took 1.09 seconds to load)
1 example, 0 failures
```

Let's commit our changes:

```
$ git add .
$ git commit -m 'created basic articles query scaffolding'

```

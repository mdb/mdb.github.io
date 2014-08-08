---
title: Rails API Integration Tests
date: 2014/04/17
tags: ruby, rspec, continuous integration
thumbnail: legos_thumb.png
teaser: A simple pattern for authoring integration tests for a Rails app.
---

A web-services-oriented architecture encourages the development of multiple, modular applications over maintaining a single large, all-in-one monolithic piece of software. Often, the web services paradigm involves the development of clients apps that rely upon third party RESTful web services. Labor and responsibilities are divided and conquered across smaller, more manageable codebases and teams. But how can such a client application verify graceful integration? With a large user-base, such insight is increasingly critical.

<b>Example</b>: You're deploying a Rails application that consumes a third party REST API, massages its data, and serves JSON. Unit tests stub HTTP requests with webmock; they verify that the application behaves as expected given prescribed data scenarios. But how do you ensure that both the upstream service, as well as your application, <i>actually</i> integrate as expected in a production scenario with real HTTP transactions, not just the stubbed responses you anticipate? How will you know in advance if your release candidate fails to gracefully handle an unnoticed third party API change? Or if you've introduced a bug in consuming third party data?

API versioning and hypermedia standards such as [HAL](http://stateless.co/hal_specification.html) promise non-breaking changes. From this perspective such verification is arguably unnecessary. But what about human error and unanticipated problems? Mistakes happen. And what about services that don't promise non-breaking changes?

<b>Solution</b>: Simple Rspec integration tests ensure your application appropriately handles real HTTP requests against the third party service. The following offers a basic pattern in Rails. I assume you're using [Rspec](http://rspec.info/) and that your unit tests stub HTTP request with [webmock](https://github.com/bblimke/webmock).

Create a `config/environments/integration.rb` config file:

```ruby
# inherit the test.rb config values
load(Rails.root.join("config", "environments", "test.rb"))

YourApp::Application.configure do
  # integration-specific overrides can go here
end
```

Create some conditional logic in your `spec_helper.rb` surrounding This excludes Rspec tests tagged `:integration` unless the `RAILS_ENV` environment variable is set to 'integration'.

```ruby
RSpec.configure do |config|
  config.filter_run_excluding :integration unless ENV['RAILS_ENV'] == 'integration'
end

# disables HTTP requests for all non-integration tests
WebMock.disable_net_connect!
```

Create an integration test file:

```bash
$ touch spec/integration/api/user_spec.rb
```

And add the following test code:

```ruby
require 'spec_helper'

describe "/api/user", :integration => true do
  subject { response }

  before :each do
    WebMock.disable!
    get 'api/user'
  end

  context "the API requests succeed as expected" do
    its(:status) { should eq 200 }
  end

  context "verifying its JSON attributes" do
    subject { JSON.parse(response.body) }

    its(['username']) { should eq 'mdb' }
  end
end
```

Create a Rake task to run the integration tests:

```bash
$ touch lib/tasks/integration.rake
```

With the following code:

```ruby
require 'rspec/core/rake_task'

namespace :integration do
  desc "integration test the JSON API endpoints"
  RSpec::Core::RakeTask.new(:test) do |t|
    # set the RAILS_ENV such that :integration tagged
    # specs are run
    ENV['RAILS_ENV'] = 'integration'

    # only run those files in the 'integration' directory
    t.pattern = "./spec/integration{,/*/**}/*_spec.rb"
  end
end
```

Run your integration tests:

```bash
$ rake integration:test
```

Integration tests can be run against each build. Such tests could also be run periodically against your production code, thus alerting the team should a breaking change our outtage occur.

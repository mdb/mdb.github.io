---
title: Rails API Integration Tests
date: 2014/04/17
tags: ruby, rspec, continuous integration
published: false
---

Problem: You're deploying a Rails application that consumes a third party Rest API, massages its data, and serves JSON. Unit tests stub HTTP requests with webmock and verify that the application behaves as expected given prescribed data scenarios. But how do you ensure that both the downstream service, as well as your application <i>actually</i> integrate as expected in a production scenario with real HTTP transactions, not just stubbed responses? How will you know in advance if your release candidate fails to gracefully handle an unnoticed third party API change?

API versioning and hypermedia standards such as HAL promise non-breaking changes; from this perspective such tests are unnecessary. Still, Others prefer to protect against arguably possible human error and unanticipated problems. Plus, not all external services adhere to such convention.

Solution: Simple Rspec integration tests that ensure your application appropriately handles real HTTP requests against the third party service. The following offers a basic pattern.

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
```

Add an integration test to `spec/integration/:

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

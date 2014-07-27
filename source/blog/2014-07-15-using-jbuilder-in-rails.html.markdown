---
published: false
---

# Building and Testing JSON endpoints in Ruby on Rails with jBuilder

Historically, a conventional Ruby on Rails application leverages server-side business logic, a relational database, and a RESTful CRUD architecture to serve dynamically-generated HTML. However, JavaScript-intensive applications and growing use of external web APIs somewhat challenge this architecture. In many cases a Rails application is tasked in serving as an orchestration layer, collecting data from various backend services and serving reformatted JSON or XML to client applications. In such instances, how is Ruby on Rails' model-view-controller architecture still relevant? In this tutorial, we'll create a simple Rails backend that makes requests to an external XML-based web service, massages its response, and serves JSON. We'll use RSpec, jBuilder, and VCR.

## What are we building?

In this tutorial, we'll create `Noterizer`, a simple Rails app that makes a request to external, XML-based endpoints, and re-renders the XML data as an internal JSON-based endpoint. I've created [NotesService](http://notesservicedemo.herokuapp.com), a basic external web service that serves two XML-based endpoints:

* [http://notesservicedemo.herokuapp.com/note-one](http://notesservicedemo.herokuapp.com/note-one)
* [http://notesservicedemo.herokuapp.com/note-two](http://notesservicedemo.herokuapp.com/note-two)

Why is this necessary in a real world scenario? Fronting external endpoints with our own JSON endpoint opens a few opportunities:

1. Noterizer's endpoint could serve JavaScript clients who can't connect across domain names to the original, external API.
2. Noterizer's endpoint could reformat the externally hosted data to better serve its own clients' data formatting preferences.
3. Noterizer's endpoint is a single interface to the data our clients' need, while multiple requests are abstracted away by its backend.
4. Noterizer provides caching opportunities. While it's beyond the scope of this tutorial, Rails can cache external request data, thus offloading traffic to the external API and avoiding any terms of service or rate limit violations imposed by the external service.

## Set Up

For this tutorial, I am using Mac OS 10.9.4, Ruby 2.1.2, and Rails 4.1.4.

I've created a basic Rails 4 `noterizer` app. Clone its repo, enter the project directory, and check out its `tutorial` branch:

```
$ git clone http://github.com/mdb/noterizer && cd noterizer && git checkout tutorial
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

Let's make few adjustments to our RSpec installation.

First, because `Noterizer` does not use a relational database, let's delete the following `ActiveRecord` reference in `spec/rails_helper.rb`:

```ruby
# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!
```

Next, let's configure our RSpec installation to be less verbose in its warning output; such verbose warnings are beyond the scope of this tutorial. Remove the following line from `.rspec`:

```
--warnings
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

Note that a default Rails installation assumes tests live in a `tests` directory. RSpec uses a `spec` directory. For clarity's sake, let's delete the `test` directory from `noterizer`:

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
$ rails g controller notes
```

Note that this created quite a few files, including JavaScript files, stylesheet files, and a helpers module. These are not relevant to our `NotesController`; let's undo our controller generation by removing all untracked files from the project. Note that you'll want to commit any changes you do want to preserve.

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
$ rails g controller notes
```

Let's add a basic `NotesController#index` test to `spec/controllers/notes_spec.rb`. The test looks like this:

```ruby
require 'rails_helper'

describe NotesController, :type => :controller do
  describe '#index' do
    before :each do
      get :index
    end

    it 'successfully responds to requests' do
      expect(response).to be_success
    end
  end
end
```

This test currently fails when running `rake spec`, as we haven't yet created a corresponding route.

Let's add the following route to `config/routes.rb`:

```ruby
 get 'notes' => 'notes#index'
```

The test still fails when running `rake spec`, now because there isn't a proper `#index` controller action.

Let's create an empty `index` method  in `app/controllers/notes_controller.rb`:

```ruby
class NotesController < ApplicationController
  def index
  end
end
```

`rake spec` still yields failing tests, this time because we haven't yet created a corresponding view. Let's create a view:

```
$ touch app/views/notes/index.json.jbuilder
```

To use this view, we'll need to tweak our NotesController a bit. Let's ensure that requests to the `/notes` route always returns JSON via a `before_filter` run before each controller action:

```ruby
class NotesController < ApplicationController
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

Let's write one more test, asserting that the response returns the correct content type. Add the following to `spec/controllers/notes_controller_spec.rb`:

```ruby
it 'returns JSON' do
  expect(response.content_type).to eq 'application/json'
end
```

Assuming `rake spec` confirms that the second test passes, commit the changes:

```
$ git add .
$ git commit -m 'created basic notes scaffolding'

```

## Beefing up the Noterizer backend.

Currently, our NotesController doesn't do much beyond serve JSON with an empty response body, yet the goal is to serve a JSON array representing the XML data served by the `notesservicedemo.herokuapp.com` endpoints at [/note-one](http://notesservicedemo.herokuapp.com/note-one) and [/note-two](http://notesservicedemo.herokuapp.com/note-two).

## The model

First, let's create a model to represent the note data returned by each of the `notesservicedemo.herokuapp.com` endpoints. In a more traditional Rails application, such a model represents data from a database. In `JbuilderDemo`, the `Note` model represents XML data served by `notesservicedemo.herokuapp.com`.

Create a `Note` model:

```
$ touch app/models/note.rb
```

On initialization, the `Note` should perform an HTTP request to the URL it's passed on instantiation, and expose relevant XML values via some public methods. The `Note` class will use [nokogiri]() to parse the XML.

Require the `nokogiri` gem by adding the following to your Gemfile:

```ruby
gem 'nokogiri'
```

Install `nokogiri`:

```
$ bundle install
```

Add the following to `app/models/note.rb`:

```ruby
require 'nokogiri'

class Note
  def initialize(url = nil)
    @uri = URI.parse(url)
    @xml = get_and_parse_response

    create_methods
  end

  private

  def get_and_parse_response
    Nokogiri::XML(get_response)
  end

  def get_response
    http = Net::HTTP.new(@uri.host, @uri.port)

    http.request(request).body
  end

  def request
    Net::HTTP::Get.new(@uri.request_uri)
  end

  def create_methods
    available_methods.each do |method|
      self.class.send(:define_method, method) { fetch_value method.to_s }
    end
  end

  def available_methods
    [
      :to,
      :from,
      :heading,
      :body
    ]
  end

  def fetch_value(value)
    @xml.xpath("//add[@key='#{value}']/@value").text
  end
end
```

The `Note` class now works as follows:

1. It performs an HTTP request to the URL it's passed on initialization
2. It leverages Nokogiri to parse the resulting XML
3. It uses Nokogiri's support of XPATH expressions to dynamically create `to`, `from`, `heading`, and `body` methods based on the corresponding values in the XML.

Let's create a corresponding `note` model spec.

```
$ rails g rspec:model note
```

First, let's test the `Note#to` method by adding the following to `spec/models/note_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Note, :type => :model do
  before do
    @note = Note.new('http://notesservicedemo.herokuapp.com/note-one')
  end

  describe '#to' do
    it 'returns the correct "to" value from the XML' do
      expect(@note.to).to eq 'Samantha'
    end
  end
end
```

Running `rake spec` reveals that the test passes, though the test performs a real HTTP request. This is not ideal: it generates unwelcome traffic on `notesservicedemo.herokuapp.com`, makes hard-coded assumptions about the XML returned by the `/note-one` endpoint, and relies upon an internet connection to pass.

Let's configure RSpec to use `webmock` to fake HTTP requests.

Add `webmock` to the Gemfile:

```ruby
gem 'webmock', group: :test
```

Install `webmock`:

```
$ bundle install
```

Add the following to `spec/spec_helper.rb` to disable network requests during RSpec runs:

```ruby
require 'webmock/rspec'

RSpec.configure do |config|
  WebMock.disable_net_connect!
end
```

Now, let's use webmock to stub the `notesservicdemo` request/response in `spec/models/note_spec.rb` by making the `before` block the following:

```ruby
before :each do
  url = 'http://notesservicedemo.herokuapp.com/note-one'

  stub_request(:get, url).to_return(
    body: [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<note type="work">',
        '<add key="to" value="Samantha"/>',
        '<add key="from" value="David"/>',
        '<add key="heading" value="Our Meeting"/>',
        '<add key="body" value="Are you available to get started at 1pm?"/>',
      '</note>'
    ].join('')
  )

  @note = Note.new(url)
end
```

Running `rake spec` should now run the full test suite, including the `Note` model spec, without performing real HTTP requests.

Similar tests can be authored for `Note`'s `from`, `heading`, and `body` methods. Examples can be viewed in `noterizer`'s `master` branch.

## The controller

Now that we have a `Note` model, our `Notes#index` controller should create an instance variable, inside of which lives an array of `Note` models representing each `notesservicedemo` endpoint.

Add the following to `app/controllers/notes_controller.rb`'s `index` method:

```ruby
def index
  url_base = 'http://notesservicedemo.herokuapp.com'

  @notes = [
    Note.new("#{url_base}/note-one"),
    Note.new("#{url_base}/note-two")
  ]
end
```

## The controller tests

Let's test the modifications to `NotesController`.

### Making a spec helper

To test the controller, we'll need to stub the `notesservicedemo.herokuapp.com` requests, just as was done in `spec/models/note_spec.rb`.

However, rather than repeat the stub, let's abstract it into a helper that can be used throughout the specs.

Create a `spec/support/helpers.rb` file:

```
$ mkdir spec/support && touch spec/support/helpers.rb
```

Define the helper method by adding the following to the newly created `spec/support/helpers.rb` file:

```ruby
module Helpers
  def stub_note_request(path)
    base_url = "http://notesservicedemo.herokuapp.com"

    stub_request(:get, "#{base_url}/#{path}").to_return(
      body: [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<note type="work">',
          '<add key="to" value="Samantha"/>',
          '<add key="from" value="David"/>',
          '<add key="heading" value="Our Meeting"/>',
          '<add key="body" value="Are you available to get started at 1pm?"/>',
        '</note>'
      ].join('')
    )
  end
end
```

Tweak the RSpec configuration such that it can be used by adding the following to the `configure` block in `spec/rails_helper.rb`:

```ruby
config.include Helpers
```

Edit the `spec/models/note_spec.rb`'s `before` block to use the `#stub_note_request` helper:

```ruby
before :each do
  stub_note_request('note-one')

  @note = Note.new('http://notesservicedemo.herokuapp.com/note-one')
end
```

Confirm that all tests continue passing by running `rake spec`.

### Adding new NotesController tests

Let's make use of the `stub_note_request` helper by changing `spec/controllers/notes_controller_spec.rb`'s `before` block to the following:

```ruby
before :each do
  stub_note_request('note-one')
  stub_note_request('note-two')

  get :index
end
```

And add the following to its `#index` tests to test the new functionality:

```ruby
context 'the @notes it assigns' do
  it 'is an array containing 2 items' do
    expect(assigns(:notes).length).to eq 2
  end

  it 'is an array of Note models' do
    assigns(:notes).each do |note|
      expect(note).to be_a Note
    end
  end
end
```

Assuming `rake spec` confirms that all tests still pass, commit your changes:

```
$ git add .
$ git commit -m 'created fully working NotesController'
```

## The jBuilder view

With a fully functional `Note` model and `NotesController`, Noterizer now needs a jBuilder view to render the proper JSON.

### Writing the jBuilder view templates

Add the following to `app/views/notes/index.json.jbuilder`:

```ruby
json.array! @notes, partial: 'note' as: :note
```

Create an `app/views/notes/_note.json.jbuilder` partial file:

```
$ touch app/views/notes/_note.json.jbuilder
```

Add the following to `app/views/notes/_note.json.jbuilder`:

```ruby
json.toField    note.to
json.fromField  note.from
json.heading    note.heading
json.body       note.body
```

Now, when running Noterizer's server and viewing `http://localhost:3000/notes` in the web browser, the following JSON is rendered:

```

[{
  "toField": "Samantha",
  "fromField": "David",
  "heading": "Our Meeting",
  "body": "Are you available to get started at 1pm?"
},{
  "toField": "Melissa",
  "fromField": "Chris",
  "heading": "Saturday",
  "body": "Are you still interested in going to the beach?"
}]
```

### Testing the jBuilder view templates

First, let's test the `app/views/notes/_note.json.jbuilder` template. Create a spec file:

```
$ mkdir spec/views/notes && touch spec/views/notes/_note.json.jbuilder_spec.rb
```

Add the following to the newly created `_note` spec:

```
require 'spec_helper'

describe 'notes/_note' do
  let(:note) do
    double('Note',
      to: 'Mike',
      from: 'Sam',
      heading: 'Tomorrow',
      body: 'Call me after 3pm.',
    )
  end

  before :each do
    assign(:note, note)

    render '/notes/note', note: note
  end

  context 'verifying the JSON values it renders' do
    subject { JSON.parse(rendered) }

    describe "['toField']" do
      subject { super()['toField'] }

      it { is_expected.to eq 'Mike' }
    end

    describe "['fromField']" do
      subject { super()['fromField'] }

      it { is_expected.to eq 'Sam' }
    end

    describe "['heading']" do
      subject { super()['heading'] }

      it { is_expected.to eq 'Tomorrow' }
    end

    describe "['body']" do
      subject { super()['body'] }

      it { is_expected.to eq 'Call me after 3pm.' }
    end
  end
end
```

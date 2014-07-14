---
published: false
---

# Using Teaspoon to Test JavaScript in a Rails Application

Through HTML5 and JavaScript frameworks such as [Angular]() and [Backbone](), more and more web applications serve a large JavaScript layer.
The Ruby on Rails community strongly encourages
automated testing; numerous tools such as [Rspec](http://rspec.info/) and
[Cucumber](http://cukes.info/) seek to assist developers in
testing Ruby. Yet, with the advent of more JavaScript-intensive applications, a larger degree of
functionality and business logic lives on the clientside where it's executed in
the user's browser rather than a Ruby-powered backend. In the case of these
JavaScript-heavy applications, how can developers ensure their applications
feature full test coverage through all layers of the software, including the
JavaScript frontend? Tools such as [Jasmine](http://jasmine.github.io/) and
[Mocha](http://visionmedia.github.io/mocha/) help, but
what's the best way to integrate these technologies with a Ruby on Rails
project? Teaspoon is a full-featured JavaScript test runner built specifically
for Rails; it respects the Rails asset pipeline, can be run headlessly in
continuous integration, and supports code coverage analysis.

In this tutorial, we'll walk through setting up Teaspoon to test a simple Ruby on Rails-based
Backbone application. We'll use Jasmine as a
testing framework and Istanbul to analyze test coverage.

## Setting up the TeaspoonDemo Rails project

For this excercise, I'm using git, Mac OS 10.9.4, Ruby 2.1.2, and Rails 4.1.4. I
am assuming some very basic familiarity with git, the Mac OS command line, and
Ruby on Rails.

Open a terminal, clone the `teaspoon-demo` Rails project's `tutorial` branch, and enter the project
directory:

```
$ git clone https://github.com/mdb/teaspoon-demo && cd teaspoon-demo && git checkout tutorial
```

Install its dependencies:

```
$ bundle install
```

Confirm your Rails app is working.

Start the server:

```
$ rails s
```

Visit `http://localhost:3000` in your web browser and confirm that the demo works.
You should see the following:

TODO: insert image

## A Quick Tour of the TeaspoonDemo Application

TeaspoonDemo is a largely out-of-the-box Ruby on Rails installation with just a
few points of note.

### CoffeeScript, Turbolinks, and jQuery UJS

[CoffeeScript](http://coffeescript.org/),
[Turbolinks](https://github.com/rails/turbolinks), and
[jquery-ujs](https://github.com/rails/jquery-ujs) are used in default Rails 4
installations, though they're beyond the scope of this tutorial.
`teaspoon-demo` is a simple Backbone application authored in plain JavaScript.

These dependencies and their configuration have been removed from TeaspoonDemo
via [this commit](https://github.com/mdb/teaspoon-demo/commit/b4f5bf8827d72a95dbf814c1afac7dd8a2e87316).

### The homepage

For demo purposes, `teaspoon-demo`'s Rails backend is very light; it doesn't do
much beyond serve a homepage.

The Teaspoon backend is set up via [this commit](https://github.com/mdb/teaspoon-demo/commit/b1880cb37281c46db47860bdfce29e042ed20d69):

### Rails Assets

[RubyGems](https://rubygems.org) addresses Ruby package and dependency
management, but what about JavaScript dependencies? [Bower](http://bower.io/) is
a frontend package manager; [Rails Assets](https://rails-assets.org/) re-packages
Bower components as Ruby gems and exposes them to the Rails asset pipeline.

TeaspoonDemo leverages Rails Assets to install and manage its
[Underscore](http://underscorejs.org/) and [Backbone](http://backbonejs.org/)
dependencies via [this commit](https://github.com/mdb/teaspoon-demo/commit/08ffaf534efab2491937e83ba9c537a7733ac9dc).

### The Backbone application

TeaspoonDemo establishes a very basic Backbone application that renders a
simple list of teas on its homepage. This code can be viewed in
`app/assets/javascripts`:

```
├── application.js
├── collections
│   └── tea_collection.js
├── home.js
├── models │
    └── tea.js
├── templates
│   └── tea_list_item.js
└── views
    ├──tea_list.js
    └── tea_list_item.js
```

Tools like [RequireJS](http://requirejs.org/) and
[Browserify](http://browserify.org/) offer JavaScript module-authoring
solutions, though these aren't used in `teaspoon-demo`, which utilizes a simple `TD` namespace to house its application code.

## Teaspoon

With `teaspoon-demo` cloned locally and running, we're ready to start setting up
Teaspoon.

### Install Teaspoon

Add the teaspoon v0.8.0 gem to the Gemfile:

```ruby
gem 'teaspoon', '0.8.0'
```

Install:

```
$ bundle install
```

With the Teaspoon gem installed, `teaspoon-demo` now has a teaspoon
generator. Its options can be viewed via the following command:

```
$ rails generate teaspoon:install --help
```

By default, the Teaspoon generator uses plain JavaScript rather than
CoffeeScript. It also uses Jasmine as its test framework, though
[Mocha](http://visionmedia.github.io/mocha/) and
[QUnit](http://qunitjs.com/)
are also available.

Run the Teaspoon generator to create a default teaspoon installation:

```
$ rails generate teaspoon:install
```

This creates a `spec` directory with the following layout:

```
├── javascripts
│   ├── fixtures
│   ├── spec_helper.js
│   └── support
└──teaspoon_env.rb
```

We also now have a `teaspoon` command, as well as a `teaspoon` rake task.
Run the `teaspoon` rake task:

```
$ rake teaspoon
```

This should fail and output an error. The top-most line of the error output
reads as follows:

```
Error: ActionView::Template::Error: Asset filtered out and will not be
served: add `Rails.application.config.assets.precompile += %w( teaspoon.css)` to
`config/initializers/assets.rb` and restart your server
```

This error occurs because the Rails asset pipeline needs to precompile the
teaspoon-provided assets alongside the `teaspoon-demo` assets. Fix this error
by stopping your Rails server and adding the following to
`config/initializers/assets.rb`:

```ruby
Rails.application.config.assets.precompile += %w( teaspoon.css )
Rails.application.config.assets.precompile += %w( jasmine/1.3.1.js )
Rails.application.config.assets.precompile += %w( teaspoon-jasmine.js )
Rails.application.config.assets.precompile += %w( teaspoon-teaspoon.js )
```

Now, running `rake teaspoon` should produce the following output:

```
$ rake teaspoon Starting the Teaspoon server...
Teaspoon running default suite at http://127.0.0.1:52813/teaspoon/default

Finished in 0.00000 seconds 0 examples, 0 failures
```

Teaspoon can also be viewed in the browser at
`http://localhost:3000/teaspoon`, assuming your Rails server is running. This is especially helpful as it allows developers to leverage the browser's JavaScript console in debugging code.

### Writing the first test

With teaspoon installed and configured, `teaspoon-demo`'s JavaScript can now be
tested with Jasmine. I
won't cover the mechanics of Jasmine tests, though the following
test spec serves as a simple example:

```javascript
// spec/javascripts/views/tea_list_spec.js
describe("TD.views.TeaList", function () {
  beforeEach(function () {
    this.testContainer = $('<ul class="teas"></ul>');

    this.view = new TD.views.TeaList({
      el: this.testContainer,
      collection: new TD.collections.Tea([{
        name: 'Some Tea',
        type: 'Some Type'
      }, {
        name: 'Some Second Tea',
        type: 'Some Second Type'
      }])
    });
  });

  it("is a Backbone view", function () {
    expect(this.view instanceof Backbone.View).toEqual(true);
  });

  describe("#render", function () {
    beforeEach(function () {
      this.view.render();
    });

    it("renders a list item and appends it to the 'el' for each tea model in its collection", function () {
      expect(this.view.$('li').length).toEqual(2);
    });

    describe("each list item it renders", function () {
      beforeEach(function () {
        this.listItem = this.view.$('li')[0];
      });

      it("displays the tea's name", function () {
        expect($(this.listItem).find('h2').text()).toEqual('Some Tea');
      });

      it("displays the tea's type", function () {
        expect($(this.listItem).find('p').text()).toEqual('Type: Some Type');
      });
    });
  });
});
```

Add the above-posted spec code to `spec/javascripts/views/tea_list_spec.js`.
Re-running the `teaspoon` rake task now reports four passing tests:

```
$ rake teaspoon
Starting the Teaspoon server...
Teaspoon running default suite at http://127.0.0.1:56131/teaspoon/default
....

Finished in 0.00500 seconds
4 examples, 0 failures
```

### Code Coverage with Istanbul

`teaspoon-demo` now
has some passing tests but how well-tested is the remainder of the application's
JavaScript? Teaspoon's [Istanbul](http://gotwarlost.github.io/istanbul/)
integration can help assess this.

Istanbul runs on [Node.js](http://nodejs.org/). Download and install Node
v0.10.29 from [nodejs.org](http://nodejs.org).

In Ruby, [bundler](http://bundler.io/) is used to manage Ruby gem
dependencies. In the Node.js world, [npm](https://www.npmjs.org/) is used to
manage Node.js module dependencies. Let's install Istanbul with npm:

```
$ npm install -g istanbul
```

Teaspoon/Istanbul integration requires a few configuration changes. Make the following edits to `spec/teaspoon_env.rb`:

Specify 'default' as the value of `config.use_coverage` on line 160:

```ruby
# Specify that you always want a coverage configuration to be used.
config.use_coverage = 'default'
```

Specify what coverage reports Istanbul should generate on line 167. Let's
generate a text summary output to the terminal, as well as an HTML report:

```ruby
# Which coverage reports Instanbul should generate. Correlates directly to
what Istanbul supports.
#
# Available: text-summary, text, html, lcov, lcovonly, cobertura, teamcity
coverage.reports = ["text-summary", "html"]
```

Specify a directory where Istanbul should store the HTML coverage report on line
171. Note that this option is originally called `coverage.output_dir`; this is a
bug. Let's change it to the correct `config.output_path` and specify a value:

```ruby
# The path that the coverage should be written to - when there's an artifact
to write to disk.
# Note: Relative to `config.root`.
coverage.output_path = "coverage/javascript"
```

Now, let's examine `teaspoon-demo`'s JavaScript code coverage. You should see the following when running the `teaspoon` rake task:

```
$ rake teaspoon
Starting the Teaspoon server...
Teaspoon running default suite at http://127.0.0.1:55583/teaspoon/default ....

Finished in 0.00600 seconds 4 examples, 0 failures

=============================== Coverage summary ===============================
Statements   : 85.29% ( 29/34 )
Branches     : 50% ( 10/20 )
Functions    : 100% ( 5/5 )
Lines        : 85.29% ( 29/34 )
================================================================================
```

Istanbul generated an HTML coverage report too; it's stored in a `coverage/javascript` directory as specified in the `teaspoon_env.rb`. This can be
viewed in your browser:

```
$ open coverage/javascript/default/index.html
```

The `coverage` directory can be ignored from git source control. Add the
following to the `teaspoon-demo/.gitignore` file:

```
coverage
```

### Establishing a Coverage Threshold

Teaspoon can also be configured to fail if JavaScript test coverage does
not meet a defined threshold. This is especially helpful in enforcing a code quality standard across a team.

Configure TeaspoonDemo's `teaspoon` rake task to fail if JavaScript isn't 100%
tested by editing the coverage threshold configurations beginning on line 173 of
`spec/teaspoon_env.rb` to look like this:

```ruby
# Various thresholds requirements can be defined, and those thresholds will be
# checked at the end of a run. If any aren't met the run will fail with a
# message. Thresholds can be defined as a percentage (0-100), or nil.
coverage.statements = 100
coverage.functions  = 100
coverage.branches   = 100
coverage.lines      = 100
```

Now, `rake teaspoon` fails with the following output:

```
$ rake teaspoon
Starting the Teaspoon server...
Teaspoon running default suite at http://127.0.0.1:55921/teaspoon/default ....

Finished in 0.00600 seconds 4 examples, 0 failures

=============================== Coverage summary ===============================
Statements   : 85.29% ( 29/34 )
Branches     : 50% ( 10/20 )
Functions    : 100% ( 5/5 )
Lines        : 85.29% ( 29/34 )
================================================================================

Coverage for statements (85.29%) does not meet threshold (100%)
Coverage for branches (50%) does not meet threshold (100%)
Coverage for lines (85.29%) does not meet threshold (100%)

rake teaspoon failed
```

Viewing the coverage report in a web browser allows more granular examination of exactly where `teaspoon-demo` lacks tests.

### Conclusion

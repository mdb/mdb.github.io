---
title: Automating Product Availability Alerts
date: 2014/03/27
published: false
tags: heroku, twilio, sinatra, capybara, automation
teaser: Too much internet. Automate your web browsing.
---

<strong>Problem</strong>: I'm renovating my kitchen. The Ikea sink I want is currently unavailable but may be back in stock any day, though Ikea's website requires its users to jump through some hoops in determining the sink's availabilty.

<strong>Solution</strong>: I made a web service that monitors the Ikea website and sends me a text message if the sink is suddenly in stock again.

<strongs>Tool chain</strong>: Rake, Capybara, Poltergeist, Sinatra, Twilio, and Heroku.

## Step 1: Create a Twilio Account

Create an account with [Twilio](https://www.twilio.com).

## Step 2: Create a basic Sinatra application

Assuming you've got Ruby installed, set up a basic project. Create a directory for the project, a Gemfile to house its gem dependencies, an app.rb file to house your web application's code, and a Rakefile in which you'll write a basic scraper task.

```
mkdir sink_watcher
cd sink_watcher
touch Gemfile
touch app.rb
touch Rakefile
```

Add the necessary Ruby gems to your Gemfile:

```ruby
source 'https://rubygems.org'

gem 'poltergeist'
gem 'sinatra'
gem 'capybara'
gem 'twilio-ruby'
```

Install the gems:

```
bundle install
```

Set up a basic homepage to your application by adding the following to your app.rb file:

```ruby
require 'twilio-ruby'
require 'sinatra'

get '/' do
  puts 'hello'
end
```

Run your application:

```
ruby app.rb
```

Visit its homepage in your web browser to verify all works as expected. You should see "hello."

```
open localhost:4567
```

Create a rake task.

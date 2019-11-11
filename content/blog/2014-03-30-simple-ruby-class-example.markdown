---
title: A Simple Ruby Class Example
date: 2014/03/30
tags:
- ruby
- rspec
- TDD
- HTTP
thumbnail: ./images/thumbnails/beach_chair_thumb.png
teaser: A basic Ruby class example to illustrate a few of the language's features.
---

Some colleagues asked about basic Ruby examples. The following RemoteConfig class makes an HTTP request and provides an object-oriented interface to XML served at the URL requested. The class serves as simple intro to some common needs and Ruby-oriented language features:

* dynamic method definition
* performing GET requests over HTTPS
* creating a basic, object-oriented interface
* parsing attribute-heavy XML with XPATH queries
* testing with [Rspec](http://rspec.info/) and [Webmock](https://github.com/bblimke/webmock)

## The XML

Assume the following XML is hosted at https://somedomain.com/config.xml:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <add key="first_key" value="first key value" />
  <add key="second_key" value="second key value" />
  <add key="third_key" value="third key value" />
  <add key="fourth_key" value="fourth key value" />
</configuration>
```

## The Ruby

A Ruby class providing an interface to the above-cited XML could like like this:

```ruby
require 'net/http'
require 'uri'
require 'nokogiri'

class RemoteConfig
  attr_reader :xml

  # On instantiation, perform an HTTP request to the XML
  # config file, parse it with nokogiri, and define methods
  # through which its values can be accessed:
  def initialize
    @xml = get_and_parse_config

    create_methods
  end

  # A method to store the XML endpoint
  def url
    "https://somedomain.com/config.xml"
  end

  # private methods; not publicly exposed for use
  # in an RemoteConfig instance
  private

  # Perform a GET request to retrieve the remote XML
  # and parse the response with Nokogiri
  def get_and_parse_config
    Nokogiri::XML(get_remote_config)
  end

  # Set up Net::HTTP to perform a GET request against
  # the remote XML URL using HTTPS.
  # Retrieve the response body.
  def get_remote_config
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    http.request(request).body
  end

  # Perform the HTTP request to the XML file:
  def request
    Net::HTTP::Get.new(uri.request_uri)
  end

  # parse the URL string as a URI
  def uri
    URI.parse(url)
  end

  # Use xpath to fetch the relevant attribute value:
  def fetch_value(value)
    @xml.xpath("//add[@key='#{value}']/@value").text
  end

  # An array of the methods we want a RemoteConfig
  # instance to have:
  def available_methods
    [
      :first_key,
      :second_key,
      :third_key,
      :fourth_key
    ]
  end

  # Rather than repeat our method logic, define the public
  # instance methods on instantantiation of the class:
  def create_methods
    available_methods.each do |method|
      self.class.send(:define_method, method) { fetch_value method.to_s }
    end
  end
end
```

## Usage

```ruby
# instantiate an instance of RemoteConfig
config = RemoteConfig.new

config.first_key
# => 'first key value'

config.second_key
# => 'second key value'

config.url
# => 'https://somedomain.com/config.xml'
```

## Testing

I'm assuming you're using Rspec and webmock, and that you have a spec_helper.rb file.

Your spec_helper.rb contains the following:

```ruby
require 'webmock/rspec'
require 'remote_config'

# Disable real HTTP network requests when
# running our tests:
WebMock.disable_net_connect!
```

And the spec looks like this:

```ruby
require 'spec_helper'

describe RemoteConfig do

  subject(:remote_config) { described_class.new }

  before :each do

    # Use webmock to stub HTTP requests to return the value we expect:
    stub_request(:get, 'https://somedomain.com/config.xml').to_return(
      :status => 200,
      :body => '<?xml version="1.0" encoding="UTF-8"?>
        <configuration>
          <add key="first_key" value="first key value" />
          <add key="second_key" value="second key value" />
          <add key="third_key" value="third key value" />
          <add key="fourth_key" value="fourth key value" />
        </configuration>'
    )
  end

  # Test its public methods:

  describe "#initialize" do
    it "creates a Nokogiri XML document" do
      expect(remote_config.xml.class).to eq(Nokogiri::XML::Document)
    end
  end

  describe "#first_key" do
    subject { remote_config.first_key }

    it { should eq 'first key value' }
  end

  describe "#second_key" do
    subject { remote_config.second_key }

    it { should eq 'second key value' }
  end

  describe "#third_key" do
    subject { remote_config.third_key }

    it { should eq 'third key value' }
  end

  describe "#url" do
    subject { remote_config.url }

    it { should eq 'https://somdomain.com/config.xml' }
  end
end
```

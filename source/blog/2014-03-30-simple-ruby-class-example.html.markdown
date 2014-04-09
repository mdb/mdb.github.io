---
title: A Simple Ruby Class Example
date: 2014/03/30
tags: ruby
published: false
---

Some colleagues are learning Ruby. I recently wrote a class similar to the following RemoteXmlConfig. The class serves as good into to some common needs and Ruby-oriented language features:

* defining methods via metaprogramming
* performing HTTP requests
* creating a basic, object-oriented interface
* parsing attribute-heavy XML with XPATH queries
* error handling
* testing a Ruby class

## The XML

Let's pretend this is hosted at http://somedomain.com/config.xml.

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

A Ruby interface to the above-cited XML:

```ruby
require 'net/http'
require 'uri'
require 'nokogiri'

class RemoteXmlConfig
  attr_reader :xml

  def initialize
    @xml = get_and_parse_config

    create_methods
  end

  def url
    "https://somedomain.com/config.xml"
  end

  private

  def get_and_parse_config
    Nokogiri::XML(get_remote_config)
  end

  def get_remote_config
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    http.request(request).body
  end

  def request
    Net::HTTP::Get.new(uri.request_uri)
  end

  def uri
    URI.parse(url)
  end

  def fetch_value(value)
    @xml.xpath("//add[@key='#{value}']/@value").text
  end

  def available_methods
    [
      :first_key,
      :second_key,
      :third_key,
      :fourth_key
    ]
  end

  def create_methods
    available_methods.each do |method|
      self.class.send(:define_method, method) { fetch_value method.to_s }
    end
  end
end
```

## Usage

```ruby
config = RemoteConfig.new

config.first_key
# => 'first key value'

config.second_key
# => 'second key value'

config.url
# => 'https://somedomain.com/config.xml'
```

## Testing

I'm assuming your using Rspec, webmock, and that you have a spec_helper.rb file.

Your spec_helper.rb contains the following to disable network requests:

```ruby
WebMock.disable_net_connect!
```

```ruby
require 'spec_helper'

describe RemoteConfig do

  subject(:remote_config) { described_class.new }

  before :each do
    stub_request(:get, 'https://somedomain.com').to_return(
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

  describe "#initialize" do
    it "creates a Nokogiri XML document" do
      expect(remote_config.xml.class).to eq(Nokogiri::XML::Document)
    end
  end

  describe "#first_key" do
    it "returns the correct value from the remote XML config file" do
      expect(remote_config.first_key).to eq 'first key value'
    end
  end

  describe "#second_key" do
    it "returns the correct value from the remote XML config file" do
      expect(remote_config.second_key).to eq 'second key value'
    end
  end

  describe "#third_key" do
    it "returns the correct value from the remote XML config file" do
      expect(remote_config.third_key).to eq 'third key value'
    end
  end

  describe "#url" do
    it "returns the URL from which the values are retrieved" do
      expect(remote_config.url).to eq 'https://somdomain.com/config.xml'
    end
  end
end
```

---
title: Using the phl_geocode Ruby Gem
date: 2012/12/17
tags: ruby, philadelphia, gem
thumbnail: default_thumb.gif
---

I recently released <a href="http://github.com/mdb/phl_geocode.rb">phl_geocode</a>, a simple Ruby gem which gets latitude and longitude coordinates for a Philadelphia address.

## Getting Started

<b>1.</b> Install phl_geocode:

```
gem install phl_geocode
```

<b>2.</b> Require phl_geocode:

```
require "phl_geocode"
```
<b>3.</b> Instantiate a PHLGeocode instance:

```ruby
phl = PHLGeocode.new
```

<b>4.</b> Get latitude/longitude coordinates for a philadelphia address:

```ruby
phl.get_coordinates "1500 market street"
```

Example response:

```ruby
[{
  :address => "1500 MARKET ST",
  :similarity => 100,
  :latitude => 39.9521740263203,
  :longitude => -75.1661518986459
}, {
  :address => "1500S MARKET ST",
  :similarity => 99,
  :latitude => 39.9521740263203,
  :longitude => -75.1661518986459
}]
```

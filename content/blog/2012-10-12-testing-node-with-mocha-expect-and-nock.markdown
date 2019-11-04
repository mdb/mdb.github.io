---
title: Testing Node.js with Mocha, Expect.js, and Nock
date: 2012/10/12
tags:
- javascript
- node.js
- mocha
- tdd
thumbnail: yellow_spark_thumb.png
teaser: A technique for mocking HTTP requests in your Node.js tests.
---

<strong>Problem</strong>: Your Node.js code uses <a href="https://github.com/voxpelli/node-request">request</a> or <a href="http://nodejs.org/api/http.html">http</a> to make http requests to URLs. You don&#8217;t want to make actual http calls, nor do you want to test request and/or http. How can you test that your code works as intended and interfaces properly with request and http?

<strong>Solution</strong>: Use <a href="https://github.com/flatiron/nock">nock</a>. For the purposes of this example, I&#8217;ll also demonstrate how nock works in concert with <a href="http://visionmedia.github.com/mocha">mocha</a> and <a href="https://github.com/LearnBoost/expect.js">expect.js</a>.

## Your node module

```javascript
// Let's call this file/module flickr-feeder.js
var request = require("request")
  , _ = require("underscore");

exports.getFlickrJSON = function(params, callback) {
  var url = "http://api.flickr.com/services/feeds/photos_public.gne";
  var paramsObj = {
    'format': 'json'
  };

  _.extend(paramsObj, params);

  request(url, {qs: paramsObj}, function (error, response, body) {
    callback(body);
  });
};
```

## Example Usage

```javascript
var ff = require('flickr-feeder');
// get JSON data from http://api.flickr.com/services/feeds/photos_public.gne?id=someFlickrID&#038;format=json
ff.getFlickrJSON({id: 'someFlickrID'}, function (data) {
  console.log(data); // the JSON response from Flickr
});
```

## Test Code

```javascript
// This file is lives in test/flickr-feeder.js
var flickrFeeder = require('../flickr-feeder.js')
  , nock = require('nock')
  , expect = require('expect.js');

describe("flickrFeeder", function() {
  describe("#getFlickrJSON", function () {

    // verify that the getFlickrJSON method exists
    it("exists as a public method on flickrFeeder", function () {
      expect(typeof flickrFeeder.getFlickrJSON).to.eql('function');
    });

    // verify that the getFlickrJSON method calls the correct URL
    it("makes the correct http call to Flickr's API based on the parameters it's passed", function () {

      // use nock
      nock('http://api.flickr.com')
        .get('/services/feeds/photos_public.gne?format=json&#038;id=someFlickrID')
        .reply(200, {'some_key':'some_value'});

      flickrFeeder.getFlickrJSON({id: 'someFlickrID'}, function (data) {
        expect(data).to.eql({'some_key':'some_value'});
      });
    });
  });
});
```

## Run your test

```
cd your_flickr_feeder_directory
mocha
```

See the full example code on Github <a href="http://github.com/mdb/flickr-feeder">here</a>.

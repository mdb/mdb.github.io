---
title: Using Mocha to Test a Node.js Server
date: 2012/08/15
tags: javascript, node.js, mocha, tdd
thumbnail: pattern_thumb.png
teaser: Using Node.js's fork to write tests against a server.
---

How do you write Mocha tests against a Node.js server and run the tests during development, presumably while your server is already running?

<b>Solution</b>: Leverage <code>fork</code> to run the server code as a child process of the Mocha test. The following is a quick example of what this could look like.

## The Server Code

Let's assume this code lives in <code>your-project/server.js</code>.

```javascript
var http = require('http');
var util = require('util');
var port = process.env.PORT || 4824;

http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(port, function () {
  util.log('Listening on port ' + port);

  if (process.send) {
    process.send('listening');
  }
});
```

## Mocha Test Code

Let's assume this code lives in <code>your-project/test/server.js</code>.

```javascript
var assert = require("assert");
var request = require("request");
var fork = require("child_process").fork;

describe('auther', function () {
  var child,
      port = 6666;

  before( function (done) {
    child = fork('auther.js', null, {env: {PORT: port}});
    child.on('message', function (msg) {
      if (msg === 'listening') {
        done();
      }
    });
  });

  after( function () {
    child.kill();
  });

  it('listens on the specified port', function (done) {
    request('http://127.0.0.1:' + port, function(err, resp, body) {
      assert(resp.statusCode === 200);
      done();
    });
  });
});
```

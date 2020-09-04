---
title: How to Test Google Polymer elements on Travis CI
date: 2015/06/06
tags:
- ci
- testing
- travis
- polymer
- javascript
thumbnail: polymer_thumb.png
teaser: How to run a headless Firefox on Travis CI via Xvfb
---

Problem: how do you design a cloud-based continuous integration pipeline if your automated application tests relies on technology that requires a GUI, or an actual web browser? [Google Polymer](https://www.polymer-project.org) heavily leverages [Shadow DOM](https://w3c.github.io/webcomponents/spec/shadow/), a feature that's not currently supported in headless JavaScript environments like [PhantomJS](http://phantomjs.org/). My [polymer-testing-box](http://github.com/mdb/polymer-testing-box) demonstrate how to run such tests via [Xvfb](http://en.wikipedia.org/wiki/Xvfb) on a headless Ubuntu VM. Can this technique be used on [Travis CI](http://travis-ci.org)?

Travis CI supports Xvfb and Firefox. Travis offers [documentation](http://docs.travis-ci.com/user/gui-and-headless-browsers/) on leveraging these technologies in its CI environment.

In short, Xvfb can be spun up in advance of test execution. web-component-tester tests can be run in Firefox.

Example `.travis.yml`:

```
language: node_js
node_js:
  - "0.12"
before_install:
  - "npm install -g bower"
  - "bower install"
  - "npm install -g web-component-tester"
  - "export DISPLAY=:99.0"
  - "sh -e /etc/init.d/xvfb start"
script: "wct"
```

I created a [js-polymer-wct-seed](http://github.com/kata-seeds/js-polymer-wct-seed) Kata Seed as a more robust example, somewhat based off the [Polymer Startup Kit](https://github.com/PolymerElements/polymer-starter-kit).

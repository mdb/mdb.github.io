---
title: How to Make Testable Private Methods in JavaScript
date: 2011-05-11
tags:
- javascript
- notes
- tdd
thumbnail: lock_thumb.png
teaser: A controversial technique for writing unit tests against private methods.
---

**Problem**: how to write unit tests for private functions?

As my co-worker Trevor [suggests in more detail](http://trevmex.com/post/5365259743/a-javascript-template-for-making-testable-private), one solution is to create a class with 3 internal objects:

* **settings**: this object houses configuration options, such as a debug option
* **private**: this object houses private functions
* **public**: this object houses all public functions

Then, in writing unit tests, a developer can instantiate the class by passing `{debug: true}` to adjust the class's settings such that the private and public objects are merged, in effect exposing the previously private functions housed in the private object.

Note that this technique is a bit controversial amongst those who argue that the need to test private functions hints at larger code problems, specifically that the private functions are too complex. Also note that it requires `jQuery`.

## Example Code

```javascript
if (typeof NS === 'undefined' || !NS) {
    var NS = {};
}
(function ($) {
  NS.Klass = function(options) {
    var settings = {
      debug: false
    },
    private = {
      // Private Functions
    },
    public = {
      // Public Functions
    };

    if (options) {
      $.extend(settings, options);
    }

    if (settings.debug) {
      return $.extend({}, private, public);
    } else {
      return public;
    }
  };
}(jQuery));
var myClass = new NS.Klass(); // Regular usage
var myDebugClass = new NS.Klass({debug: true}); // Debug usage
```

---
title: "Fluent 2012 Notes: Nicholas Zakas on Maintainable JavaScript"
date: 2012/05/31
tags: javascript, fluent
thumbnail: glasses_thumb.png
---

<p><em>My notes from <a href="http://www.nczonline.net/">Nicholas Zakas</a>' 2012 Fluent talk on Maintainable JavaScript.</em></p>

<p>The primary features of maintainable code:</p>

<ul>
  <li>works for at least 5 years without major changes</li>
  <li>intuitive</li>
  <li>understandable</li>
  <li>adaptable - developers must be able to change without breaking completely</li>
  <li>extendable - the code can be built upon to do more than was originally intended</li>
  <li>debuggable - developers should be able to easily identify the source of problems</li>
  <li>testable - code that can be validated with unit tests saves time and ensures quality</li>
</ul>

<p>Maintainability requires coordination. Individual developers must set aside ego and personal process in favor of what's best for the team. Chris Epstein, the creator of Compass: "Be kind to your future self."</p>

<p>Conventions and style guides help developers communicate through code. Google's JavaScript style guide is a good example and point of reference. Crockford's opinions, as well as <a href="https://github.com/rwldrn/idiomatic.js">idiomatic.js</a>, also serve as strong examples. Computer Scientist Knuth: "Programs are meant to be read by humans and only incidentally for computers to execute." Independent of what style standards you adopt, the less code that lives on one line, the less likely you'll encounter a merge conflict.</p>

<p>Camel casing is a good standard in JavaScript, as this is how JavaScript's APIs are denoted. But what about acronyms such as those in <code>innerHTML</code>, <code>getElementById</code>, <code>XMLHttpRequest</code>? Try and forgive JavaScript's own inconsistencies in this area and decide upon a standard amongst your team.</p>

<p>Self-documenting code is a myth; comments are valuable and make code more understandable. Java docs-style comments offer a good starting point.</p>

<p>Good naming helps ensure maintainability. Variables and functions should have logical and descriptive names. Don't worry about length; if you're concerned with size, obfuscate your JavaScript via a minifier. Variable names should be nouns. Function names should be verbs. Functions which return a boolean value should begin with "is" or "has." For example: <code>isGoodFuncName();</code>. Constant-like variables can be named in all caps. For example: <code>SOME_VARIABLE = 'foo'</code>. Constructors' first letter should be capitalized.</p>

<p>Remember to separate the layers of your front end: presentation (CSS), behavior (JavaScript), and data (HTML). <code>&lt;button onclick="someFunction();" /&gt;</code> confuses these layers and is less easily debugged. Conversely, concatenating HTML strings in JavaScript (<code>var htmlStr = '&lt;div&gt;&lt;p&gt;' + somePara + '&lt;/p&gt;&lt;/div&gt;'</code>) is also not ideal. Consider a JavaScript templating language such as Moustache instead.</p> 

<p>Event handlers: event handlers should be small and limited in what they do. Developers should also be wary of passing around the event object. Consider the following:</p>

```javascript
// bad - the click handler does too much:
function handleClick(event) {
  // do a bunch of stuff with event to show a modal dialog
}

// better - the click handler does one thing:
function handleClick(event) {
  showModalDialog(event);
}

function showModalDialog(event) {
  // do a bunch of stuff with event to show a modal dialog
}

// best - the click handler does one thing and we no longer pass around the event object:
function handleClick(event) {
  showModalDialog(event.clientX, event.clientY);
}

function showModalDialog(clientX, clientY) {
  // do a bunch of stuff with clientX and clientY to show a modal dialog
}
```

<p>Don't add new methods on objects you don't own. <code>Array.prototype.awYeah = function() { alert('Yeah!') }</code> is problematic, as it challenges other developers' expectations surrounding the behavior of Array. Similarly, don't override methods and avoid global functions and variables.</p>

<p>Throwing errors is helpful.</p>

<p>Checking <code>someStrVar instanceof String</code> or <code>someArrVar instanceof Array</code> is preferable to <code>someStrVar !== null</code>, as it's more explicit and safe.</p>

<p>Strings of configuration data should be kept away from application logic where they're harder to change.</p>

<p>Bad: <code>var error = 'some/path/to/error.html';</code>.</p>

<p>Good: var config {errorHref: 'some/path/to/error.html'}; var error = config.errorHref;</code>.</p>

<p>Nicholas Zakas' <a href="https://github.com/nzakas/props2js">props2js</a> can help turn Java properties files to JavaScript.</p>

<p>Finally, automation is valuable. Build processes are great.</p>

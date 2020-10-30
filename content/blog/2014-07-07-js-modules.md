---
title: JavaScript Modules
date: 2014-07-07
tags:
- javascript
thumbnail: default.png
published: false
teaser: A few notes on JavaScript modules.
---

The next version of JavaScript features a module system. [jsmodules.io](http://jsmodules.io/) offers a clear overview.

My notes...

## Defining a module

```javascript
// a file called hello.js
var hello;

hello = function () {
  console.log('hello');
};

export default hello;
```

## Importing and using a module:

```javascript
// a file called using.js
import hello from "hello";

hello();
// => hello
```

## Named exports

A module with multiple exports:

```javascript
// a file called hello.js
var hello,
    hola;

hello = function () {
  console.log('hello');
};

hola = function () {
  console.log('hola');
};

export default hello;
export var hola;
```

Grouped named exports:

```javascript
export { hello, hola, bonjour };

function hello() {
  console.log('hello');
}

function hola() {
  console.log('hola');
}

function bonjour() {
  console.log('bonjour');
}
```

## Named imports

Basic usage:

```javascript
import { hola } from "hello";

hola();
// => hola
```

Renaming named imports:

```javascript
import { hola as hi } from "hello";

hi();
// => hola
```

Importing all a module's exports into a local namespace:

```javascript
import * as greeter from "hello";

greeter.hello();
// => hello

greeter.hola();
// => hola
```

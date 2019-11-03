---
title: JavaScript Design Patterns
date: 2011/03/19
tags:
- javascript
- notes
thumbnail: pink_pattern_thumb.png
teaser: My notes on Addy Osmani's JavaScript design patterns ebook.
---

Addy Osmani offers Essential [JavaScript & jQuery Design Patterns For Beginners](http://www.addyosmani.com/resources/essentialjsdesignpatterns/book/) as a free guide to some solutions "that can be applied to commonly occurring problems" throughout JavaScript. Here are a few of my notes on Osmani’s book, mostly for my own reference:

## The Creational Pattern

* used in creating objects within in application
* define a class and instantiate it later when you need it

```javascript
var newObject = new MyClass();
```

## The Constructor Function

* used to create specific types of objects
* native constructors in JavaScript include Array and Object
* constructor functions often capitalized to distinguish them from normal functions

```javascript
function Car(model, year, miles){
  this.model = model;
  this.year = year;
  this.miles = miles;
  this.whatCar = function(){
    console.log(this.model);
  };
}

var civic = new Car("Honda Civic", 2009, 20000);
var mondeo = new Car("Ford Mondeo", 2010, 5000);
```

## The Singleton Pattern

* can be implemented by creating a class with a method that creates a new instance of the class if one doesn’t exist
* if an instance exists, it returns a reference to that object
* traditionally, restricts instantiation of a class to a single object
* doesn’t provide a way for code that doesn’t know about a previous reference to the singleton to easily retrieve it
* it is not the object or class that’s returned by a singleton, it's a structure
* useful when exactly one object is needed to coordinate patterns across the system

```javascript
var SingletonTester = (function() {

  //args: an object containing arguments for the singleton
  function Singleton(args) {

   //set args variable to args passed or empty object if none provided.
    var args = args || {};
    //set the name parameter
    this.name = 'SingletonTester';
    //set the value of pointX
    this.pointX = args.pointX || 6; //get parameter from arguments or set default
    //set the value of pointY
    this.pointY = args.pointY || 10;

  }

 //this is our instance holder
  var instance;

 //this is an emulation of static variables and methods
  var _static = {
    name: 'SingletonTester',
   //This is a method for getting an instance

   //It returns a singleton instance of a singleton object
    getInstance: function (args){
      if (instance === undefined) {
        instance = new Singleton(args);
      }
      return instance;
    }
  };
  return _static;
})();

var singletonTest = SingletonTester.getInstance({pointX: 5});
console.log(singletonTest.pointX); // outputs 5 
```

## The Module Pattern

* way to provide both private and public encapsulation for the idea of JavaScript ‘classes’
* work under the premise of a ‘class’ actually being defined as a function
* parameters that you decide to use for this class are actually the parameters for the constructor
* local variables and functions defined inside your class become private members
* return method for your class (ie. still a function) returns an object that contains your public methods and variables

## Advantages

* cleaner than true encapsulation for developers coming from an object-oriented background
* public parts of your code are able to touch the private parts
* outside world is unable to touch the class’s private parts

## Disadvantages

* as you access both public and private members differently, when you wish to change visibility, you actually have to make changes to each place the member was used
* You also can’t access private members in methods that are added to the object at a later point.

```javascript
var someModule = (function() {

  //private attributes
  var privateVar = 5;

  //private methods
  var privateMethod = function() {
    return 'Private Test';
  };

  return {
    //public attributes
    publicVar : 10,
    //public methods
    publicMethod : function() {
      return ' Followed By Public Test ';
  },

  //let's access the private members
  getData : function() {
    return privateMethod() + this.publicMethod() + privateVar;
   }
 }
})(); //the parens here cause the anonymous function to execute and return

someModule.getData();
```

## The Revealing Module Pattern

* improvement to Module pattern by Christian Heilmann
* define all of your functions and variables in the private scope and return an anonymous object at the end of the module along with pointers to both the private variables and functions you wish to reveal as public
* allows the syntax of your script to be fairly consistent
* makes it very clear at the end which of your functions and variables may be accessed publicly
* provides ability to reveal private functions with more specific names if you wish

```javascript
// The idea here is that you have private methods
// which you want to expose as public methods.

// Below we are defining we a self-executing function
// and immediately returning the object.

var myRevealingModule = function() {
 var name = 'John Smith';
 var age = 40;

 function updatePerson() {
   name = 'John Smith Updated';
 }
 function setPerson () {
   name = 'John Smith Set';
 }
 function getPerson () {
   return name;
 }

 return {
   set: setPerson,
   get: getPerson
}
}();

// Sample usage:
myRevealingModule.get();
```

## The Prototype Pattern

* based on the concept of prototypal inheritance where we create objects which act as prototypes for other objects
* prototype object itself is effectively used a blueprint for each object the constructor creates.
* easy way to implement inheritance
* performance boost

```javascript
// No need for capitalization as it's not a constructor
var someCar = {
  drive: function() {};
  name: 'Mazda 3'
};

// Use Object.create to generate a new car
var anotherCar = Object.create(someCar);
anotherCar.name = 'Toyota Camry';
```

## The Facade Pattern

* simplifies the interface of a class and it also decouples the class from the code that utilizes it
* provide us with an ability to indirectly interact with subsystems in a way that may be less prone to error than accessing the subsystem directly

```javascript
//simplifying an interface for attaching events
var addMyEvent = function(el,ev,fn) {
  if (el.addEventListener) {
   el.addEventListener(ev,fn, false);
  } else if (el.attachEvent) {
   el.attachEvent('on'+ev, fn);
  } else {
   el['on' + ev] = fn;
  }
};
```

## The Factory Pattern

* deals with the problem of creating objects without need to specify the exact class of object being created
* suggests defining an interface for creating an object where you allow the subclasses to decide which class to instantiate
* defines a completely separate method for the creation of objects and which sub-classes are able to override so they can specify ‘type’ of factory product created

```javascript
var Car = (function() {
  var Car = function (model, year, miles){
   this.model = model;
   this.year   = year;
   this.miles = miles;
  };
  return function (model, year, miles) {
    return new Car(model, year, miles);
  }
})();

var civic = new Car("Honda Civic", 2009, 20000);
var mondeo = new Car("Ford Mondeo", 2010, 5000);
```

## The Decorator Pattern

* alternative to creating subclasses
* can be used to wrap objects within another object of the same interface and allows you to both add behaviour to methods and also pass the method call to the original object (ie the constructor of the decorator)
* used when you need to keeping adding new functionality to overridden methods
* subclassing adds behaviour that affects all the instances of the original class, whilst decorating can add new behavior for individual objects

```javascript
//The class we're going to decorate
function Macbook(){
  this.cost = function() {
    return 1000;
  };
}

function Memory(macbook) {
  this.cost = function() {
    return macbook.cost() + 75;
  };
}

function BlurayDrive(macbook) {
  this.cost = function() {
    return macbook.cost() + 300;
  };
}

function Insurance(macbook) {
  this.cost = function(){
    return macbook.cost() + 250;
  };
}

// Sample usage
var myMacbook = new Insurance(new BlurayDrive(new Memory(new Macbook())));
console.log( myMacbook.cost() );
```

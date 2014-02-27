---
title: 'Automated Tests: What, Why, How?'
date: 2014/02/08
tags: TDD, jasmine, Rspec, automation
thumbnail: trianglescape_thumb.png
---

In recent years, automated testing has gained significant traction as a software development best practice. But not everyone's sold or fully understands where to begin in developing such tests.

Some teams fear test-writing may impact velocity. Some believe an ill-designed, legacy codebase makes such tests impossible. Others don't fully grasp the benefits. And others simply don't know where to begin.

I'm frequently asked about automated testing &mdash; managers, product owners, UX designers, junior developers, and the uninitiated want to know: Why write tests? Where can I learn more? How do I get started?

Recently, I ran into a colleague on the West Philly Route 34 trolley. We discussed automated testing; his questions inspired me to capture some of my answers in writing...

## High level definition

What do I have in mind when I say "automated testing"? At a high level, I'm referring to some process through which software's source code can be executed and its quality verified.

What does this look like? Generally, such tests take the form of what are called functional, integration, and/or unit tests and can be executed via a build tool, task manager, or some easy-to-start process. Popular build tools include [Rake](http://rake.rubyforge.org/) in the Ruby world, [Grunt](http://gruntjs.com/) and [Gulp](http://gulpjs.com/) for Node.js JavaScript, and [Maven](http://maven.apache.org/what-is-maven.html) in the Java world. Plain old [shell scripts](http://en.wikipedia.org/wiki/Shell_script) are fine too. Ideally, the automated tests are run by individual developers in development, as well as in [continuous integration](http://en.wikipedia.org/wiki/Continuous_integration). See [Travis CI](https://travis-ci.org/) and [Jenkins](http://jenkins-ci.org/) for go-to continuous integration solutions.

## Why write tests?

+ Tests ensure that code works exactly as it should. A robust test suite can help identify the bugs an engineer failed to consider. How does the code perform if data is malformed? Is there a memory leak? Tests assist in identifying such problems before the code reaches users.
+ Tests serve to document the software's assumptions and intent, as well as its business logic and requirements. Well-written tests help explain code; tests facilitate better understanding across a team, now and in the future.
+ Tests make it easier to edit to the software's source code. Healthy software can easily accomodate rapid change to features and business requirements. When a source code edit produces test failures, an engineer is given the necessary insight to assess the edit's implications. Maybe the test failure prompts the engineer to reconsider her logic in making the edit, or maybe the test failure helps the developer identify exactly what additional edits must be made to fix the tests and accomodate the change.
+ Tests save time. Automated tests can rapidly assert software's health such that software can more confidently and more frequently be released to users.

## Where can I learn more?

Bob Martin's [The Three Rules of TDD](http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd) is a helpful read.

[Deciphering Testing Jargon](http://code.tutsplus.com/tutorials/deciphering-testing-jargon--net-27513) is a good high-level overview of software testing lexis.

## How do I get started?

Disclaimer: these days, my primary languages are Ruby and JavaScript so therein lies my bias.

I like [Rspec](http://rspec.info/) for testing Ruby; tools like [VCR](https://www.relishapp.com/vcr/vcr/docs), [webmock](https://github.com/bblimke/webmock), [capybara](http://jnicklas.github.io/capybara/) help. [SimpleCov](https://github.com/colszowka/simplecov) can measure the extent to which your code is fully tested ("code coverage").

To test JavaScript, I most often use [Jasmine](http://jasmine.github.io/), though I've also turned to [Mocha](http://visionmedia.github.io/mocha/) and [Chai](http://chaijs.com/). [Phantomjs](http://phantomjs.org/) is a headless webkit; it allows you to run your tests without a GUI web browser and works well with the aforementioned frameworks. If you're using Ruby on Rails, [teaspoon](https://github.com/modeset/teaspoon) is a flexible test runner that elegantly integrates these tools with consideration for the Rails Asset Pipeline. To measure code coverage, [istanbul](http://gotwarlost.github.io/istanbul/) leads the way.

Functional tests that simulate end-user behavior are a bit more tricky in my experience, though a combination of [cucumber](http://cukes.info/), [selenium](http://docs.seleniumhq.org/), and [capybara](http://jnicklas.github.io/capybara/) provides a powerful ecosystem. Here again, [phantomjs](http://phantomjs.org/) can be helpful in providing a headless environment. If you prefer to write such functional tests in JavaScript, [Zombie](http://zombie.labnotes.org/) and similar tools seem promising.

## Some more specific resources

The [Ruby Koans](http://rubykoans.com) provide a great intro to TDD, as well as a good framework for learning Ruby.

[Jasmine](http://jasmine.github.io/), the JavaScript testing framework, offers a helpful [online introduction](http://jasmine.github.io/2.0/introduction.html).

And [Tuts+](http://code.tutsplus.com/search?utf8=%E2%9C%93&view=&search%5Bkeywords%5D=testing) hosts a large collection of strong, easy-to-follow testing-related tutorials.

Have some other resources to share? [Reach out](http://twitter.com/clapexcitement).

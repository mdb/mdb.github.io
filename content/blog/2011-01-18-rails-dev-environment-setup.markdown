---
title: Setting up a Ruby on Rails Dev Environment
published: false
date: 2011/01/18
tags:
- ruby
- ruby on rails
- notes
thumbnail: diamond_thumb.png
teaser: Some old instructions collected for a team of Rails newcomers.
---

<b>NOTE:</b> These instructions are a bit old and were documented in 2011 for a few CIM colleagues.

The following notes are based on Trevor Lesh-Menagh's Ruby on Rails workshops. At CIM, Trevor hosts lunchtime Rails workshops each Tuesday.

Note that the following instructions apply to Mac OS X 10.6.5.

1. Install XCode
+ Install Git
+ Open Terminal.app
+ Install the latest Ruby Version Manager (RVM) code from the github repository by entering this command:
```
bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head ) 
```
+ When the installation finishes, open your ~/.bash_profile and add the following line:
   # This loads RVM into a shell session.
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 

Reload your ~/.bash_profile:

   source .bash_profile

Confirm that RVM installed correctly:

   which rvm

If RVM installed correctly, the above command should return something like the following:

   /Users/your_username/.rvm/bin/rvm

Install the proper version of Ruby. We’ll be Ruby 1.8.7:

   rvm install 1.8.7

Set Ruby 1.8.7 as your default Ruby:

   rvm --default 1.8.7

Confirm that Ruby 1.8.7 installed and is set to be your default Ruby:

   which ruby

If all is well, this should return something like the following:

   /Users/your_username/.rvm/rubies/ruby-1.8.7-p330/bin/ruby 

Install Rails:

   gem install rails

Note that Rails can be installed without its documentation like so:

   gem install rails --no-rdoc --no-ri

Confirm that Rails installed correctly and is using Ruby 1.8.7:

   which rails

If all is well, this should return something like:

   /Users/your_username/.rvm/gems/ruby-1.8.7-p330/bin/rail

cd to the directory of your choosing and make a new Rails app:

   rails new your_app_name
   cd to your_app_name

Install all the dependencies specified in your Rails app’s Gemfile
j
   bundle install

Run the Rails server:

   rails s

Visit your Rails app in your browser at http://localhost:3000/

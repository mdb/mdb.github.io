---
title: Setting up a Ruby on Rails Dev Environment
draft: true
date: 2011-01-18
tags:
- ruby
- ruby on rails
- notes
thumbnail: diamond_thumb.png
teaser: Some old instructions collected for a team of Rails newcomers.
---

**NOTE:** These instructions are a bit old and were documented in 2011 for a few CIM colleagues.

The following notes are based on Trevor Lesh-Menagh's Ruby on Rails workshops. At CIM, Trevor hosts lunchtime Rails workshops each Tuesday.

Note that the following instructions apply to Mac OS X 10.6.5.

1. Install XCode

1. Install Git

1. Open Terminal.app

1. Install the latest Ruby Version Manager (RVM) code from the github repository by entering this command:

    ```bash
    bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )
    ```

1. When the installation finishes, open your `~/.bash_profile` and add the following line:
    ```bash
    # This loads RVM into a shell session.
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
    ```

1. Reload your `~/.bash_profile`:

    ```bash
    source .bash_profile
    ```

1. Confirm that RVM installed correctly:

    ```bash
    which rvm
    ```

1. If RVM installed correctly, the above command should return something like the following:

    ```bash
    /Users/your_username/.rvm/bin/rvm
    ```

1. Install the proper version of Ruby. We’ll be Ruby 1.8.7:

    ```bash
    rvm install 1.8.7
    ```

1. Set Ruby 1.8.7 as your default Ruby:

    ```bash
    rvm --default 1.8.7
    ```

1. Confirm that Ruby 1.8.7 installed and is set to be your default Ruby:

    ```bash
    which ruby
    ```

1. If all is well, this should return something like the following:

    ```bash
    /Users/your_username/.rvm/rubies/ruby-1.8.7-p330/bin/ruby
    ```

1. Install Rails:

    ```bash
    gem install rails
    ```

1. Note that Rails can be installed without its documentation like so:

    ```bash
    gem install rails --no-rdoc --no-ri
    ```

1. Confirm that Rails installed correctly and is using Ruby 1.8.7:

    ```bash
    which rails
    ```

1. If all is well, this should return something like:

    ```bash
    /Users/your_username/.rvm/gems/ruby-1.8.7-p330/bin/rail
    ```

1. `cd` to the directory of your choosing and make a new Rails app:

    ```bash
    rails new your_app_name
    cd to your_app_name
    ```

1. Install all the dependencies specified in your Rails app’s Gemfile

    ```bash
    bundle install
    ```

1. Run the Rails server:

    ```bash
    rails s
    ```

Visit your Rails app in your browser at http://localhost:3000/

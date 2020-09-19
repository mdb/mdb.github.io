---
title: How to Set Up a Git Repository on Webfaction
date: 2010-10-26
tags:
- git
- notes
draft: true
thumbnail: default_thumb.gif
teaser: My notes on how I set up git repo hosting on Webfaction.
---

**NOTE**: This documentation is old; I don't know if these instructions still work. These days, I recommend [BitBucket](https://bitbucket.org) if you need free, private Git repositories.

GitHub is great for Git-based version control of public projects, but I recently needed to set up a private Git repostiory on my Webfaction account. This is simple to do, although not initially clear. Here’s a few notes on how to do it, mostly for my own reference:

## How to Install Git on Webfaction

1. Log into your Webfaction Control Panel
1. Navigate to Domains/Websites » Applications
1. Click Add New
1. Enter git as the application name in the Name field
1. Select git from the App category menu
1. Enter a password for the default user in the Extra Info field
1. Click the Create button
1. Git should now be installed. The installation creates a directory at `~/webapps/git`. A directory at `~/webapps/git/bin` contains the Git executables. A directory at `~/webapps/git/repos` provides a place to store your repositories, pre-populated with `~/webapps/git/repos/proj.git` serving as an example.

## How to Create a new Git Repository

1. Open an SSH session to your webfaction account: `ssh username@username.webfactional.com`
1. `cd ~/webapps/git/`
1. Enter `./bin/git init --bare ./repos/reponame.git` to create a new repository, where `reponame` is the name of yorur repository
1. `cd repos/repo.git`
1. Enable HTTP push with `../../bin/git config http.receivepack true`

## Connect it to Your Local Work

1. `cd /path/to/your/local/repository/`
1. Assuming it’s not already under version control, enter `git init`
1. `git add .`
1. `git commit -a -m 'Initial commit.'`
1. `git remote add origin ssh://username@username.webfactional.com/~/webapps/git/repos/reponame.git`
1. `git push origin master`
1. `git push`

## Clone Your Repository Somewhere New

```bash
git clone username@username.webfactional.com:webapps/git/repos/reponame.git
```

## Based On:

* Webfaction's [Git Documentation](http://docs.webfaction.com/software/git.html)
* [Git Setup on Webfaction](http://munkymorgy.blogspot.com/2010/03/git-setup-on-webfaction.html)

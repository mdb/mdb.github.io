---
title: How to use Docker in TravisCI Enterprise
date: 2016-03-31
tags:
- docker
- devops
draft: true
teaser: Running docker in your TravisCI Enterprise builds
---

Problem: [travis-ci.org](https://travis-ci.org/) offers Docker support. However, such support is a currently-de-activated beta feature in TravisCI Enterprise.

Solution: Here's how to activate Docker in TravisCI Enterprise...

Add the following to `/etc/default/travis-worker` on your Workers:

```
export TRAVIS_WORKER_DOCKER_PRIVILEGED="true"
```

Restart each Worker:

```
$ sudo status travis-worker
travis-worker start/running, process 9622

$ sudo stop travis-worker
travis-worker stop/waiting

$ sudo start travis-worker
travis-worker start/running, process 16339
```

Add the following to any .travis.yml files for repositories which would like to use Docker:

```
install:
  - sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  - echo "deb https://apt.dockerproject.org/repo ubuntu-precise main" | sudo tee /etc/apt/sources.list.d/docker.list
  - sudo apt-get update
  - sudo apt-get install docker-engine
```

For example, to test Docker support, create a `.travis.yml` with the following:

```
install:
  - sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  - echo "deb https://apt.dockerproject.org/repo ubuntu-precise main" | sudo tee /etc/apt/sources.list.d/docker.list
  - sudo apt-get update
  - sudo apt-get install docker-engine
  - sudo docker pull ubuntu

script:
  - sudo docker run ubuntu date
```

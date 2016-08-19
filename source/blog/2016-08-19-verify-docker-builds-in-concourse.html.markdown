---
title: Using the ConcourseCI pull-request Resource to verify Docker builds
date: 2016/08/19
tags: concourse, github
published: false
teaser: How to verify a Docker image pull request in ConcourseCI.
---

[Concourse.ci](http://concourse.ci) offers a free, open source continuous integration and delivery tool through which software development teams can establish and manage delivery pipelines.

*Problem*: [TravisCI](https://travis-ci.org) can be configured to run CI against a docker image's [source code repository](https://travis-ci.org/mdb/docker-wct). But how can Concourse's `pull-request` resource be configured to test that `docker build` of a `Dockerfile` works as expected in a repo that houses such a `Dockerfile`.

*Solution*: Configure the Concourse's pull request verification job to use the `docker-image` resource type.

# The pipeline.yml

```
resources:

# source code
- name: docker-foo
  type: git
  source:
    branch: master
    uri: git@github.com:username/docker-foo.git

# foo docker image
- name: foo-docker-image
  type: docker-image
  source:
    repository: docker.your-company.com/username/foo

# docker-foo pull request resource
- name: docker-foo-pull-request
  type: pull-request
  source:
    uri: git@github.comcast.com:aae/cloud-tools.git
    repo: username/docker-foo

resource_types:

- name: pull-request
  type: docker-image
  source:
    repository: jtarchie/pr

jobs:

# verify a pull request
- name: verify-pull-request
  plan:
  - get: docker-foo-pull-request
    trigger: true
  - put: docker-foo-pull-request
    params:
      path: docker-foo-pull-request
      status: pending
  # test in ConcourseCI that the PR's `Dockerfile` edits work as expected:
  - put: foo-docker-image
    params:
      build: docker-foo-pull-request
    on_success:
      put: docker-foo-pull-request
      params:
        path: docker-foo-pull-request
        status: success
    on_failure:
      put: docker-foo-pull-request
      params:
        path: docker-foo-pull-request
        status: failure

# build foo docker image from `master`
- name: publish-docker-image
  serial: true
  plan:
  - get: docker-foo
    trigger: false
  - put: foo-docker-image
    params:
      build: foo
      tag: foo/version
```

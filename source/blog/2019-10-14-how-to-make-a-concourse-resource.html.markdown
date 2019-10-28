---
title: How to Make a Concourse Resource
date: 2019/10/14
tags: concourse, ci, cd
thumbnail: TODO
teaser: How to implement a custom Concourse resource type.
---

## Context and backgrond

_Resources_ are a core concept in [Concourse](https://concourse-ci.org) CI/CD pipelines. A [resource](https://concourse-ci.org/resources.html) is any entity that Concourse can check for new versions, fetch at a specific version, and/or push up changes to idempotently create new versions. In this sense, a resource "version" is a specific form of the resource that differs from earlier forms, such as a particular commit on a git repository or a particular build artifact object in an AWS S3 bucket. This may sound a bit vague, but it's an arguably compelling feature. Because Concourse's concept of resources offers a generic way to extend Concourse functionality -- and because Concourse supports the use of custom [resource-type implementations](https://concourse-ci.org/implementing-resource-types.html) -- resources serve as a useful tool in building Concourse CI/CD pipelines. Pipeline authors can leverage Concourse's built-in resource types, use community-maintained resource types, or create new functionality through their own, custom resource types. And each implementation -- whether it's a built-in resource type, a community-maintained resource type, or a custom, in-house resource type -- is itself packaged and distributed as versioned software with its own build/test/release CI/CD lifecycle.

## Built-in resource types

Out of the box, Concourse ships with a few built-in [resource types](https://concourse-ci.org/resource-types.html). These "official" resource types are maintained by the Concourse development team and offer some common, core pipeline functionalities. A few of Concourse's built-in resource types are:

* [git-resource](https://github.com/concourse/git-resource) - used to interact with git repositories
* [s3-resource](https://github.com/concourse/s3-resource) - used to interact with AWS S3
* [docker-image-resource](https://github.com/concourse/docker-image-resource) - tracks and builds Docker images

## Community maintained resource types

Beyond the built-in Concourse resources types, community maintained resource types add additional Concourse pipeline functionalities. In my experience, complex CI/CD pipelines often lean on community maintained resource type implementations. A few popular examples include:

* [github-pr-resource](https://github.com/telia-oss/github-pr-resource) - used to interact with GitHub pull requests
* [terraform-resource](https://github.com/ljfranklin/terraform-resource) - used to interact with Terraform
* [slack-notification-resource](https://github.com/cloudfoundry-community/slack-notification-resource) - used to send notifications to Slack

## Implementing a Concourse resource type: Is it necessary?

Before developing your own, custom Concourse resource type, it's worth considering a few questions...

1. Will an existing, community-maintained resource type suffice?

    There are many open source, community-maintained Concourse resource types available for public use. In my experience, usually an existing resource type meets a pipeline's requirements. Given this large, community ecosystem, I rarely encounter a use case that warrants writing a new resource type from scratch.

2. Is a _resource_ necessary or will a [task](https://concourse-ci.org/tasks.html) suffice?

    Resources are most compelling in their ability to _track_ specific resource _versions_ -- such as a specific [GitHub release](https://help.github.com/en/github/administering-a-repository/creating-releases), for example -- across multiple Concourse pipeline [jobs](https://concourse-ci.org/jobs.html). By serving as a external-to-Concourse mechanism through which pipelines can persist and fetch state, resources empower the ability to build pipelines composed of a sequence of jobs passing and operating on specific resource versions, and dependent on their predecessors' success.

    However, if it's not necessary to pass resource versions between multiple jobs (rather than between [tasks](https://concourse-ci.org/tasks.html) _within_ a job, which support the ability to operate on and pass directories as [inputs](https://concourse-ci.org/tasks.html#input-name) and [outputs](https://concourse-ci.org/tasks.html#output-name)), you may not need a resource. Instead, a simple [task](https://concourse-ci.org/tasks.html) may meet your needs. In Concourse, _tasks_ can be authored to run any command or script in any Docker image.

## How to implement a resource type: a case study

[concourse-consul-kv-resource](https://github.com/mdb/concourse-consul-kv-resource) is a Concourse resource I maintain for interacting with [HashiCorp Consul](https://www.consul.io/)'s key/value store. It offers a relatively simple case study through which Concourse resource type anatomy can be examined.

At its core, implementing a custom Concourse resource type requires publishing a Docker image with 3 executables:

1. `/opt/resource/check` - responsible for checking for new versions of your resource
2. `/opt/resource/in` - responsible for fetching specific versions of your resource
3. `/opt/resource/out` - responsible for outputting new versions of your resource

In the case of `concourse-consul-kv-resource`, its Docker image is published to [hub.docker.com/r/clapclapexcitement/concourse-consul-kv-resource](https://hub.docker.com/r/clapclapexcitement/concourse-consul-kv-resource). Provided the a resource type Docker image properly implements the `check`, `in`, and `out` executibles (more on this to follow), the source code itself can be authored in any programming language. `concourse-consul-kv-resource` is written in Node.js.

A very basic pipeline configuration using `concourse-consul-kv-resource` might look like this (If you're unfamiliar with authoring Concourse pipelines, [concoursetutorial.com](https://concoursetutorial.com) is a great start):

```yaml
resources_types:

# declare the use of a 'consul-kv' resource type
- name: consul-kv
  type: docker-image
  source:
    repository: clapclapexcitement/concourse-consul-kv-resource
    tag: latest

resources:

# configure an instance of the 'consul-kv' resource type
- name: my-consul-key
  type: consul-kv
  source:
    host: my-consul.com
    key: my-key

jobs:

# a basic job to fetch 'my-key'
- name: get-my-consul-key
  plan:
  - get: my-consul-key

# a basic job to update 'my-key'
- name: update-my-consul-key
  plan:
  - put: my-consul-key
    params: my-new-value
```

## The "check" action: `/opt/resource/check`

`/opt/resource/check` is run to detect new versions of the resource. Resource type authors determine what constitutes a resource "version" on a per-implementation basis. In the case of `concourse-consul-kv-resource`, a version is a unique value of the Consul key specified in the resource's [source configuration](https://concourse-ci.org/resources.html#resource-source).

A basic pipeline source configuration might contain information on the specific resource, such as URLs, credentials, and other details on how the resource should interact with third party providers. As exemplified in the example above, a basic `concourse-consul-kv-resource` source configuration might contain information on a Consul instance's domain name and the specific K/V key of interest (other [source config options](TODO) are available as well):

```yaml
...
- name: my-consul-key
  type: consul-kv
  source:
    host: my-consul.com
    key: my-key
...
```

When invoked, `check` is passed a JSON payload containing the [source configuration](https://concourse-ci.org/resources.html#resource-source) and version data on `stdin`.

Example `stdin` JSON provided to the resource:

```json
{
  "source": {
    "host": "my-consul.com",
    "key": "my-key"
  },
  "version": {
    "value": "some-value"
  }
}
```

`/opt/resource/check` uses the JSON provided on `stdin` to determine if new resource versions exist. It must print a JSON array of new versions to `stdout`. Because `concourse-consul-kv-resource` uses a Consul key's value as its version, `/opt/resource/check` uses the info provided in `source` to check the `source.host` Consul instance for a new `source.key` value that differs from the current `version.value` passed via `stdin`.

If the key in Consul has a new value, `/opt/resource/check` outputs JSON such as the following to `stdout`:

```json
[{
  "value": "some-new-value"
}]
```

If the key does not have a new value, `/opt/resource/check` outputs an empty JSON array to `stdout`, indicating that no new versions were discovered:

```json
[]
```

## The "in" action: `/opt/resource/in`

`/opt/resource/in` is run to fetch a specific version of the resource. In the case of `concourse-consul-kv-resource`, `/opt/resource/in` is implemented to always fetch the current Consul key value.

When invoked, `/opt/resource/in` is provided a JSON payload on `stdin` containing the [source configuration](https://concourse-ci.org/resources.html#resource-source) and version data, similar to `/opt/resource/check`.

Example `stdin` provided to the resource:

```json
{
  "source": {
    "host": "my-consul.com",
    "key": "my-key"
  },
  "version": {
    "value": "some-value"
  }
}
```

In addition to the JSON payload, `/opt/resource/in` is passed the name of a "destination" directory as a single argument. The resource may write resource version data -- downloads, files, metadata, etc. -- to this "destination" directory such that downstream job [steps](https://concourse-ci.org/steps.html) can use these files and the data they contain. The "destination" directory's name is determined by the string specified as a job's [get step](https://concourse-ci.org/get-step.html#get-step-get).

`concourse-consul-kv-resource`'s `/opt/resource/in` uses the information provided in the `stdin` JSON `source` to fetch the `source.key` value from the `source.host` Consul instance and write its value to a file in the destination directory. For example, given the above `stdin` JSON -- and assuming the `my-key`'s value in Consul is "some value" -- the following pipeline configuration results in an invocation of `/opt/resource/in` that writes "some-value" to a `my-consul-key/my-key` file:

```yaml
- name: get-my-consul-key
  plan:
  - get: my-consul-key
```

The `/opt/resource/in` must also send JSON to `stdout` denoting version and metadata info in a standard format. The [metadata](TODO) is an array of key/value pairs denoting version-specific metadata of interest that is displayed on the Concourse web UI's build page.

For example, `concourse-consul-kv-resource`'s `/opt-resource/in` produces `stdout` JSON like the following:

```json
{
  "version": {
    "value": "some-value"
  },
  "metadata": [{
    "name": "value",
    "value": "some-value",
  }]
}
```

## The "out" action: `/opt/resource/out`

`/opt/resource/out` is run to produce a new version of a resource. In the case of `concourse-consul-kv-resource`, `/opt/resource/out` updates the Consul key specified in `source.key` in the Consul instance specified in `source.host` with a new value.

When invoked, `/opt/resource/out` is provided a `stdin` JSON payload containing source configuration and [params](TODO) data. `params` is an arbitrary key/value map of parameters. The supported `params` values vary between resource type implementations. `concourse-consul-kv-resource` supports two `params` keys:

* `value` - a string specifying the new Consul K/V key's value
* `file` - the path to a file in which the new Consul K/V key's value is written

For example, the following job step configuration results in a `stdin` JSON payload whose `params.value` field's value is "new-value:"

```yaml
- name: update-my-consul-key
  plan:
  - put: my-consul-key
    params:
      value: "new-value"
```

Assuming a basic `source` coniguration, the full `stdin` JSON would look like this:

```json
{
  "source": {
    "host": "my-consul.com",
    "key": "my-key"
  },
  "params": {
    "value": "my-new-out-value"
  }
}
```

Like `in`, `/opt/resource/out` must print `stdout` JSON denoting version and metadata in a standard format. `concourse-consul-kv-resource`'s `/opt-resource/out` produces `stdout` JSON like the following.

```json
{
  "version": {
    "value": "some-value"
  },
  "metadata": [{
    "name": "value",
    "value": "some-value",
  }, {
   "name": "timestamp",
    "value": "1572210671189",
  }]
}
```

## Execute the resource `check`, `in`, and `out` locally

Assuming [Docker](https://www.docker.com/) is installed, a resource type's `check`, `in`, and `out` implementations can be invoked via a `docker run` to exercise and validate its functionality.

To exercise `concourse-consul-kv-resource`'s functionality, it's also necessary to have a Consul instance for the resource to read from and write to. Let's start a Consul on `localhost:8500` using `docker-compose`.

First, create a `docker-compose.yml`:

```bash
cat <<EOF > docker-compose.yml
version: '3'

services:
  consul:
    image: consul
    ports:
    - 8500:8500
EOF
```

Next, use the newly-created `docker-compose.yml` to start the local `docker-compose`'d Consul on a network named `kv-resource_default`:

```bash
docker-compose \
  --project-name="kv-resource" \
  up \
    --detach
```

Note that this makes the the Consul resolvable via a `consul` hostname for any other services on the `kv-resource_default` network.

Let's also use `curl` to interact with the Consul K/V API to seed the `localhost:8500` Consul with a `my-key` key whose value is "my-value:"

```bash
curl \
  --request "PUT" \
  --data "my-value" \
  http://localhost:8500/v1/kv/my-key
```

## An example `/opt/resource/check` invocation

Store the `stdin` JSON in a file for convenience:

```bash
cat <<EOF > check_request.json
{
  "source": {
    "host": "consul",
    "protocol": "http",
    "skip_ssl_check": true,
    "key": "my-key"
  },
  "version": {
    "value": "my-value"
  }
}
EOF
```

Invoke the `check` using the `check_request.json` as `stdin`:

```bash
cat check_request.json | \
  docker run \
    --network=kv-resource_default \
    --rm \
    --interactive \
    clapclapexcitement/concourse-consul-kv-resource \
      /opt/resource/check"
```

Because the `version.value` specified in the JSON matches the `my-key`'s current value in Consul, you should see an empty array printed to `stdout`, indicating there are no new versions of `my-key`:

```json
[]
```

To see how `check` behaves when the `version.value` value is different from the `my-key`'s current value in Consul, update `my-key`'s value in Consul:

```bash
curl \
  --request "PUT" \
  --data "my-new-value" \
  http://localhost:8500/v1/kv/my-key
```

A re-execution of the above-cited `docker run` command now prints the following JSON to `stdout`, indicating that `check` has discovered a new version:

```json
[
  {
    "value": "my-new-value"
  }
]
```

## An example `/opt/resource/in` invocation

Store the `stdin` JSON in a file for convenience:

```bash
cat <<EOF > in_request.json
{
  "source": {
    "host": "consul",
    "protocol": "http",
    "skip_ssl_check": true,
    "key": "my-key"
  },
  "version": {
    "value": "my-value"
  }
}
EOF
```

Invoke the `in` using the `in_request.json` as `stdin` and write the `my-key` to a `dest/my-key` file:

```bash
cat in_request.json | \
  docker run \
    --network=kv-resource_default \
    --volume $(pwd):/dest \
    --rm \
    --interactive \
    clapclapexcitement/concourse-consul-kv-resource \
      /opt/resource/in /dest"
```

Note that, because the above `docker run` mounts your host machine's (i.e. the machine on which the `docker run` is executed) current working directory at `/dest`, this results in a `my-key` file in your host machine's current working directory. This also prints the following JSON to `stdout`:

```json
{
  "version": {
    "value": "my-value"
  },
  "metadata": [
    {
      "name": "value",
      "value": "my-value"
    }
  ]
}
```

## An example `/opt/resource/out` invocation

Next, let's invoke `/op/resource/out` with `stdin` JSON that updates the `my-key`'s value to a "my-new-value-from-params" value passed in the JSON's `params` field.

First, store the `stdin` JSON in a file for convenience:

```bash
cat <<EOF > out_request.json
{
  "source": {
    "host": "consul",
    "protocol": "http",
    "skip_ssl_check": true,
    "key": "my-key"
  },
  "params": {
    "value": "my-new-value-from-params"
  }
}
EOF
```

Invoke the `out` using the `out_request.json` as `stdin` and update the `my-key` Consul key to be "my-new-value-from-params":

```bash
cat out_request.json | \
  docker run \
    --volume $(pwd):/out-source \
    --network=kv-resource_default \
    --rm \
    --interactive \
    clapclapexcitement/concourse-consul-kv-resource \
      /opt/resource/out /out-source"
```

As a result, this prints JSON to `stdout` similar to this:

```json
{
  "version": {
    "value": "my-new-value-from-params"
  },
  "metadata": [
    {
      "name": "timestamp",
      "value": "1572272431669"
    },
    {
      "name": "value",
      "value": "my-new-value-from-params"
    }
  ]
}
```

And also note that the `my-key` in Consul is now "my-new-value-from-params." We can verify this by `curl`-ing the Consul API, using [jq](https://stedolan.github.io/jq/) to parse the JSON response, and using `base64` to decode the base64-encoded key's value:

```bash
curl \
  --silent \
  --request GET http://localhost:8500/v1/kv/my-key | \
    jq -r '.[0].Value' | \
    base64 --decode

my-new-value-from-params
```

Alternatively, we could use `/opt/resource/out`'s support of a `params.file` to update the `my-key`'s value with a value read from a file.

First, create a `my-key` file:

```
cat <<EOF > my-key
my-new-value-from-file-params
EOF
```

Next, update the `out_request.json` to use a `params.file` rather than a `params.value`:


```json
...
  "params": {
    "file": "my-key"
  }
...
```

This time, a re-invokation of the `docker run` prints JSON like the following to `stdout`:

```json
{
  "version": {
    "value": "my-value-from-file-params"
  },
  "metadata": [
    {
      "name": "timestamp",
      "value": "1572273019536"
    },
    {
      "name": "value",
      "value": "my-value-from-file-params"
    }
  ]
}
```

And the `my-key` in Consul is now "my-new-value-from-file-params:"

```bash
curl \
  --silent \
  --request GET http://localhost:8500/v1/kv/my-key | \
    jq -r '.[0].Value' | \
    base64 --decode

my-new-value-from-file-params
```

## Further reading and learning:

* [Concourse docs](TODO)
* [Pivotal article](TODO)

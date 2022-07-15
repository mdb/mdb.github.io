---
title: Terraform Provider Development Demystified
date: 2022-07-14
tags:
- infrastructure
- golang
- cloud
- terraform
thumbnail: grassy_hill_thumb.jpg
teaser: An introduction to Terraform provider development patterns
---

_Many Terraform practitioners may be unfamiliar with [provider](https://www.terraform.io/language/providers) development. How are providers actually implemented? The following offers an outline of a brief presentation I gave to the [HBO Max](https://www.hbomax.com/) Strategic Global Infrastructure team._

## Review of the basics

First, let's establish a foundation, especially for those who may be less familiar with [Terraform](https://www.terraform.io/).

### Terraform fundamentals

Terraform enables users to describe infrastructure resources -- and their dependency relationships -- in `.tf` files using [HCL](https://github.com/hashicorp/hcl), and to automate the creation and ongoing management of that infrastructure via the Terraform command line inferface.

HCL configurations often spec out resources associated with cloud infrastructure services, such as AWS, OpenStack, or Kubernetes, but they might also spec out less cloudy resources, such as local files. For example, the following configuration creates a Digigal Ocean droplet, a DNSSimple A record, and a local file documenting the droplet's IP address:

```hcl
resource "digitalocean_droplet" "web" {
  name   = "tf-web"
  size   = "512mb"
  image  = "centos-5-8-x32"
  region = "sfo1"
}

resource "dnsimple_record" "hello" {
  domain = "example.com"
  name   = "test"
  value  = digitalocean_droplet.web.ipv4_address
  type   = "A"
}

resource "local_file" "ip_address" {
  content  = digitalocean_droplet.web.ipv4_address
  filename = "${path.module}/ip_address.txt"
}
```

When invoked against a configuration (i.e. a collection of resources specified in `*.tf` files like the example above) via the `terraform plan` and/or `terraform apply` CLI commands, Terraform builds a [dependency graph of resource relationships](https://www.terraform.io/internals/graph) and resource attributes and analyzes...

1. What has been specified in the `*.tf` files?
1. How does that compare to what has been captured in [Terraform state](https://www.terraform.io/language/state)?
1. How does all that compare to what may or may not actually exist, as reported by the resources' corresponding APIs?

Based on its analysis, Terraform decides the order in which it must invoke the necessary CRUD actions ("create," "read," "update," or "destroy") against the resources' APIs in order to produce the desired state, as specified in HCL configuration in `*.tf` files. I often refer to this logic as the "Terraform lifecycle algorithm," though I may have made up that terminology; I don't know if the Terraform maintainers would view it as appropriate, though I find it helpful.

### Terraform providers

In Terraform parlance, _resources_ (such as an individual DNS record) are associated with _providers_ (such as DNSSimple or AWS Route 53). When declaring a resource in a `.tf` HCL file, the provider name appears as the `${provider name}_` prefix. In the following example, Grafana is the provider associated with a folder resource:

```hcl
resource "grafana_folder" "foo" {
  uid   = "foo"
  title = "Terraform Folder With UID foo"
}
```

As mentioned above, providers are often cloud infrastructure services such as AWS, OpenStack, Fastly, etc., but might also be...

* SaaS platforms such as Grafana, GitHub, OKTA, etc.
* a local file system, etc.

Generally speaking, a provider (and its underlying resource(s)) could be anything that can be modeled declaritively and has some sort of corresponding CRUD API(s).

Providers are decoupled from the Terraform CLI itself as independent software components, often versioned, compiled, and published to the [Terraform registry](https://registry.terraform.io/browse/providers) via their own CI/CD processes.

Providers are generally authored in Go using Terraform's [plugin SDK](https://github.com/hashicorp/terraform-plugin-sdk). So, how does this work?

## Implementing a provider

As Terraform practitioners know, a provider is configured in a Terraform configuration via a `provider "some_provider" {}` HCL configuration. For example:

```hcl
provider "aws" {
  version = "3.40"
  region  = "us-east-1"
}
```

Assuming the use of the [plugin SDK](https://github.com/hashicorp/terraform-plugin-sdk), a provider is implemented as a [*schema.Provider](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Provider) on which a few key fields are specified, most notably fields like...

* `Schema` - a `map[string]*schema.Schema` specifying the supported provider arguments and attributes
* `ResourcesMap` - a `map[string]*schema.Resource` specifying the supported resources and their related functions
* `DataSourcesMap` - a `map[string]*schema.Resource` specifying the supported data sources and their related functions
* `ConfigureFunc` - a [`ConfigureFunc`](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#ConfigureFunc) used to configure a provider, often creating and returning an API client using the provider configuration defined in `.tf` via the `provider "some_provider" {}` HCL.

To learn more:

* [`terraform-provider-grafana` example](https://github.com/grafana/terraform-provider-grafana/blob/master/grafana/provider.go)
* [`schema.Provider` Godocs](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Provider)

## Resources

Individual provider resources are managed via functions that return a [*schema.Resource](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource) on which a few key fields are specified, most notably fields like...

* `Description` - a description of the resource used to generate documentation
* `Create` - a [CreateFunc](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#CreateFunc) function for creating the resource from configuration via the provider API
* `Read` - a [ReadFunc](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#ReadFunc) function for reading the resource from configuration via the provider API
* `Update` - an [UpdateFunc](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#UpdateFunc) function for updating the resource from configuration via the provider API
* `Delete` - a [DeleteFunc](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#DeleteFunc) function for deleting the resource if/when it's removed from configuration via the provider API
* `Schema` - a `map[string]*schema.Schema` specifying the supported resource arguments and attributes
* etc.

Generally, each of the individual CRUD functions accept 2 arguments:

1. [*schema.ResourceData](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#ResourceData) - this represents the Terraform configuration.
1. an `interface{}` - this is a generic interface often homing an API client package configured by the provider and used to interact with the provider APIs

Each of the CRUD functions interact with the appropriate corresponding provider APIs to create, read, update, or delete the corresponding resource, accordingly. Each of the functions is also responsible for updating [Terraform state](https://www.terraform.io/language/state) to reflect this.

To learn more:

* [an example PR implementing a grafana_annotation resource](https://github.com/grafana/terraform-provider-grafana/pull/558)
* [schema.Resource Godocs](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource)
* [Terraform provider development tutorial](https://learn.hashicorp.com/collections/terraform/providers)

## Data sources

Terraform [data sources](https://www.terraform.io/language/data-sources) enable Terraform to _read_ outside information. Unlike resources -- which enable Terraform to create, update, and delete resources -- data sources only offer read-only functionality.

Assuming the use of the [plugin SDK](github.com/hashicorp/terraform-plugin-sdk), individual provider data sources are managed via functions that return a [schema.Resource](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource), similar to that returned by resource functions. However, a data source's `*schema.Resource` typically only specifies:

* `Description` - a description of the data source used to generate documentation
* `Read` - a function for reading the resource specified in configuration via the associated provider API
* `Schema` - a `map[string]*schema.Schema` specifying the supported resource arguments and attributes

To learn more:

* [an example PR extending the grafana_organization data source to include new attributes](https://github.com/grafana/terraform-provider-grafana/pull/551)

## Tying it together

In summary, provider implementation is largely composed of boilerplate-ish configuration code implementing the above-described types, with most of the business logic confined to the individual CRUD functions associated with individual resources. Then, finally, a `main.go` provides the entry point for the provider program.

To learn more:

* [terraform-provider-grafana example](https://github.com/grafana/terraform-provider-grafana/blob/master/main.go)

## GNUmakefile

Most provider codebases feature a `GNUmakefile` in which various build and test commands are specified.

## Testing

While individual functions can be unit tested in isolation, the plugin SDK provides an [acctest](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk@v1.17.2/helper/acctest) and testing utilities (most notably [`resource.TestCase`](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk@v1.17.2/helper/resource#TestCase)) used to author acceptance tests against provider, provider resource, and provider data source functionality.

Generally, these acceptance tests are configured to interact with real APIs associated with a given cloud provider, though some Terraform providers -- particularly those that target open source platforms or SaaS APIs -- may configure acceptance tests to interact with `localhost`-served APIs enabled via tools such as [Docker](https://www.docker.com/). For example, `terraform-provider-grafana`'s own acceptance testing utilizes a local Grafana established via [docker-compose](https://github.com/grafana/terraform-provider-grafana/blob/v1.24.0/docker-compose.yml) in local development, as well as remote instances of Grafana in CI/CD.

To run `terraform-provider-grafana`'s acceptance tests locally, install [Go](https://go.dev/) and [Docker](https://www.docker.com/), then clone the repository:

```sh
git clone git@github.com:grafana/terraform-provider-grafana.git
```

...and run the acceptance tests against a local Docker-established Grafana:

```sh
make testacc-docker
```

To learn more:

* [example PR adding tests of a new grafana_annotation resource](https://github.com/grafana/terraform-provider-grafana/pull/558)
* [example PR adding tests of new grafana_organization data source functionality](https://github.com/grafana/terraform-provider-grafana/pull/551)
* [example terraform-provider-grafana PR Drone CI/CD execution](https://drone.grafana.net/grafana/terraform-provider-grafana/1345)

## Building

Typically, [goreleaser](https://goreleaser.com/) is used to compile provider binaries across platforms and publish them as versioned GitHub releases. [terraform-provider-grafana's .goreleaser.yml](https://github.com/grafana/terraform-provider-grafana/blob/v1.24.0/.goreleaser.yml) offers a configuration example used to build and publish its own [GitHub releases](https://github.com/grafana/terraform-provider-grafana/releases).

Often, [tfplugindocs](https://github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs) is integrated with providers' build process to automate the generation of markdown documents documenting the provider; these are typically committed to a [docs](https://github.com/grafana/terraform-provider-grafana/tree/v1.24.0/docs) directory in source control.

## Releasing

Assuming the provider and its associated GitHub releases conform to some [common standards](https://www.terraform.io/registry/providers/publishing), the provider can be published to the [Terraform registry](https://www.terraform.io/registry/providers/publishing#publishing-to-the-registry). From there, it's available for use and can be downloaded by Terraform configurations in which it's referenced and configured.

## Learn more

In my experience, the codebase of an existing provider offers the best way to learn more, particularly that of a simple provider (as opposed to the [terraform-provider-aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs), whose codebase is huge and daunting). Maybe it's worth taking a look at something like [terraform-provider-dominos](https://github.com/nat-henderson/terraform-provider-dominos)? For me, `git clone`-ing provider code locally, running tests, and looking for simple areas of improvement has taught me a lot. Maybe that's helpful for you too?

It's also worth looking at [HashiCorp's own learning resources](https://learn.hashicorp.com/collections/terraform/providers).

Do you see an inaccuracy or typo in this post? [Submit a pull request](https://github.com/mdb/mdb.github.io).

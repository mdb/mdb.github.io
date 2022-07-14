---
title: Terraform Provider Development Demystified
date: 2022-07-14
tags:
- infrastructure
- golang
- cloud
- terraform
thumbnail: grassy_hill_thumb.jpg
teaser: An introduction to Terraform provider implementation patterns
---

_Many Terraform practitioners may be naive to provider development. How are providers implemented?_

## Review of the basics

### Terraform

At its core, Terraform enables users to describe infrastructure resources -- and their dependency relationships -- in `.tf` files using [HCL](https://github.com/hashicorp/hcl).

These HCL-declared infrastructure resources are often associated with cloud infrastructure services, such as AWS, OpenStack, or Kubernetes, but they might also be local files:

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
  value  = "${digitalocean_droplet.web.ipv4_address}"
  type   = "A"
}
```

When invoked against a configuration (i.e. a collection of resources specified in `*.tf` files) via the `terraform plan` or `terraform apply` CLI commands, Terraform builds a dependency graph of resource relationships and attributes and analyzes...

1. what has been specified in the `*.tf` files?
1. how does that compare to what has been captured in [Terraform state](https://www.terraform.io/language/state)?
1. how does all that compare to what may or may not actually exist, as reported by the resources' corresponding APIs?

Based on its analysis, Terraform decides the order in which it must invoke the necessary CRUD ("create," "read," "update," or "destroy") actions against the resources' APIs in order to produce the desired state, as specified in `*.tf` configuration.

### Terraform providers

Resources are associated with _providers_. When declaring a resource in a `.tf` HCL file, the provider name appears as the `${provider name}_` prefix. In the following example, Grafana is the provider associated with a folder resource:

```hcl
resource "grafana_folder" "foo" {
  uid   = "foo"
  title = "Terraform Folder With UID foo"
}
```

As mentioned, providers are often cloud infrastructure services such as AWS, OpenStack, Fastly, etc., but might also be...

* SaaS platforms such as Grafana, GitHub, OKTA, etc.
* a local file system, etc.

Generally speaking, a provider could be anything that can be modeled declaritively and has some sort of corresponding CRUD API (or collection of CRUD APIs).

Providers are decoupled from the Terraform CLI itself as independent software components, often versioned, compiled, and published to the [Terraform registry](https://registry.terraform.io/browse/providers) via their own CI/CD processes.

Providers are generally authored in Go using Terraform's [plugin SDK](github.com/hashicorp/terraform-plugin-sdk). How does this work?

## Specifying a provider

Assuming the use of the [plugin SDK](https://github.com/hashicorp/terraform-plugin-sdk), a provider is specified via a [*schema.Provider](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Provider) on which a few key fields are specified, most notably fields like...

* `Schema` - a `map[string]*schema.Schema` specifying the supported provider arguments and attributes
* `ResourcesMap` - a `map[string]*schema.Resource` specifying the supported resources and their related functions
* `DataSourcesMap` - a `map[string]*schema.Resource` specifying the supported data sources and their related functions

To learn more:

* [`schema.Provider` Godocs](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Provider)
* [`terraform-provider-grafana` example](https://github.com/grafana/terraform-provider-grafana/blob/master/grafana/provider.go)

## Resources

Individual provider resources are managed via functions that return a [*schema.Resource](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource) on which a few key fields are specified, most notably fields like...

* `Description` - a description of the resource used to generate documentation
* `Create` - a function for creating the resource from configuration via the provider API
* `Read` - a function for reading the resource from configuration via the provider API
* `Update` - a function for updating the resource from configuration via the provider API
* `Delete` - a function for deleting the resource if/when it's removed from configuration via the provider API
* `Schema` - a `map[string]*schema.Schema` specifying the supported resource arguments and attributes
* etc.

Generally, the individual CRUD functions accept a [schema.ResourceData](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#ResourceData) argument whose value from comes from Terraform configuration. The functions' implementation interacts with the appropriate corresponding provider APIs to create, read, update, or delete the corresponding resource, accordingly.

To learn more:

* [an example PR implementing a `grafana_annotation` resource](https://github.com/grafana/terraform-provider-grafana/pull/558)
* [`schema.Resource` Godocs](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource)
* [Terraform provider development tutorial](https://learn.hashicorp.com/collections/terraform/providers)

## Data sources

Terraform [data sources](https://www.terraform.io/language/data-sources) enable Terraform to _read_ outside information. Unlike resources -- which enable Terraform to create, update, and delete resources -- data sources are read-only.

Assuming the use of the [plugin SDK](github.com/hashicorp/terraform-plugin-sdk), individual provider data sources are managed via functions that return a [schema.Resource](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk/helper/schema#Resource), similar to that returned by resource functions. However, a data source's `*schema.Resource` typically only specifies:

* `Description` - a description of the data source used to generate documentation
* `ReadContext` - a function for reading the resource specified in configuration via the associated provider API
* `Schema` - a `map[string]*schema.Schema` specifying the supported resource arguments and attributes

To learn more:

* [an example PR extending the `grafana_organization` data source](https://github.com/grafana/terraform-provider-grafana/pull/551)

## Tying it together

Finally, `main.go` provides the entry point for the provider program.

To learn more:

* [`terraform-provider-grafana` example](https://github.com/grafana/terraform-provider-grafana/blob/master/main.go)

## GNUMakefile

Most provider codebases feature a `GNUMakefile` in which various build and test commands are specified.

## Testing

While individual functions can be unit tested in isolation, the plugin SDK provides an [acctest](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk@v1.17.2/helper/acctest) and types (most notably [`resource.TestCase`](https://pkg.go.dev/github.com/hashicorp/terraform-plugin-sdk@v1.17.2/helper/resource#TestCase)) used to author acceptance tests against provider, provider resource, and provider data source functionality.

Generally, these acceptance tests are configured to target real APIs provided by cloud providers, though some Terraform providers -- particularly those that target open source provider platforms or SaaS APIs -- may configure acceptance tests to interact with `localhost`-hosted APIs enabled via tools such as [Docker](https://www.docker.com/). For example, `terraform-provider-grafana`'s own acceptance testing utilizes a local Grafana established via [docker-compose](https://github.com/grafana/terraform-provider-grafana/blob/v1.24.0/docker-compose.yml) in local development, as well as remote instances of Grafana in CI/CD.

## Building

Typically, [goreleaser](https://goreleaser.com/) is used to compile cross-platform provider binaries and publish them as versioned GitHub releases. [terraform-provider-grafana's `.goreleaser.yml`](https://github.com/grafana/terraform-provider-grafana/blob/v1.24.0/.goreleaser.yml) offers a configuration example used to publish its [GitHub releases](https://github.com/grafana/terraform-provider-grafana/releases).

Often, [tfplugindocs](https://github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs) is integrated with providers' build process to automate the generation of markdown documents documenting the provider; these are typically committed to a [docs](https://github.com/grafana/terraform-provider-grafana/tree/v1.24.0/docs) directory in source control.

## Releasing

Assuming the provider and its associated GitHub releases conform to some [common standards](https://www.terraform.io/registry/providers/publishing), the provider can be published to the [Terraform registry](https://www.terraform.io/registry/providers/publishing#publishing-to-the-registry) where it can be downloaded by Terraform configurations that reference it and used by other Terraform practitioners.

---
title: "Terraform: natively reading GitHub release assets"
date: 2026-01-31
tags:
- terraform
- github
- iac
thumbnail: terraform2_thumb.jpg
teaser: Reading release assets in Terraform via the `github_release_asset` data source.
---

_Recently, I [contributed](https://github.com/integrations/terraform-provider-github/pull/2514)
the [github_release_asset](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release_asset) data source to the
GitHub Terraform provider. It's now available in [v6.11.0+ releases](https://github.com/integrations/terraform-provider-github/releases/tag/v6.11.0) of the
provider._

## TL;DR example

```terraform
# Fetch the most recent my-org/foo GitHub release associated with a tag.
data "github_release" "latest" {
  repository  = "foo"
  owner       = "my-org"
  retrieve_by = "latest"
}

# Fetch the deployment.yaml manifest associated with the latest GitHub release.
data "github_release_asset" "deployment_config" {
  repository             = "foo"
  owner                  = "my-org"
  asset_id               = [
    for asset in data.github_release.latest.assets :
    asset.id if asset.name == "deployment.yaml"
  ][0]
  download_file_contents = true
}
```

## Example use case

Your organization's CI/CD pipeline features distinct, loosely coupled _build_
and _deploy_ phases.

At a _build_ phase, your organization builds and publishes build artifacts --
including deployment configuration data -- as GitHub release assets.

For example, container image URIs, Kubernetes deployment descriptors, an application
version manifest, helm values, or environment-specific configuration encoded in
JSON or YAML is attached to each semantically-versioned GitHub release.

Later, at a _deploy_ phase -- decoupled from the _build_ phase -- you'd like to
read release assets' contents in Terraform and use the assets' values to drive
parameterized resource configurations applied to the targeted environment.

As an example, consider a CI/CD pipeline targeting AWS ECS:

```mermaid
flowchart TB
  subgraph build[Build Phase]
    direction LR
    artifacts[Generate artifacts] --> asset[deployment.yaml, Docker image, ECS task definition, etc.] --> release[Publish GitHub release vX.Y.Z]
  end

  build -.-> deploy

  subgraph deploy[Terraform Deploy Phase]
    direction LR
    gh_asset[Read deployment.yaml associated w/ GitHub release vX.Y.Z] --> decode[Decode its values]
    decode --> ecs[Configure AWS ECS service accordingly]
  end
```

<div class="note">
  <p>NOTE: The example targets ECS but, theoretically, the pattern could be utilized to drive any Terraform pipeline, regardless of compute platform.</p>
  <p>For example, a machine-readable <a href="https://en.wikipedia.org/wiki/Bill_of_materials">Bill of Materials</a> associated with a GitHub release could be read from multiple downstream Terraform pipelines that all use the BOM as common input data.</p>
</div>

Previously, accomplishing this with the
[GitHub Terraform provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
required workarounds: shelling out via a `local-exec` provisioner, using an
`external` data source, or fetching the asset outside Terraform and passing its
contents as a variable.

## Using the `github_release_asset` data source

Now, release asset data -- like the above described YAML or JSON files -- can be
read natively with Terraform. For example:

```terraform
variable "release" {
  type        = string
  description = "The semantically versioned tag associated with the GitHub release to deploy"
}

# Fetch the my-org/foo GitHub release associated with a tag.
data "github_release" "latest" {
  repository = "foo"
  owner      = "my-org"
  tag_name   = var.release
}

# Fetch the deployment.yaml manifest associated with the GitHub release.
data "github_release_asset" "deployment_config" {
  repository             = "foo"
  owner                  = "my-org"
  asset_id               = [
    for asset in data.github_release.latest.assets :
    asset.id if asset.name == "deployment.yaml"
  ][0]
  download_file_contents = true
}

# Decode the deployment.yaml manifest.
locals {
  deployment_config = yamldecode(
    base64decode(data.github_release_asset.deployment_config.file_contents)
  )
}

# Use local.deployment_config.* values to drive Terraform configuration.
resource "aws_ecs_service" "foo" {
  task_definition = local.deployment_config.task_arn
  ...
```

Then, to apply a specific versioned release (including a past release; in
theory, the pattern could also drive rollbacks):

```
terraform apply \
  -var "release=v1.0.3"
```

## Why? What's this give you?

YMMV, but these are the benefits I had in mind when [contributing the data
source](https://github.com/integrations/terraform-provider-github/pull/2514):

- **Native Terraform integration**: no need for awkward orchestration, like
  using `local-exec` provisioners, `external` data sources, or pre-fetching
  assets outside Terraform.
- **Human-friendly version-controlled deployments**: deploy any release by specifying its
  semantic version tag; the same mechanism can drive rollbacks to previous versions.
- **Out-of-the-box UI, API, and developer experience benefits**: GitHub provides
  a web interface for browsing releases over time, viewing changelogs, and downloading
  assets, plus a REST API for programmatic access beyond Terraform; this lends
  itself well to empowering future platform capabilities even beyond the immediate
  build/deploy use case.
- **Decoupled build and deploy**: build artifacts are immutably versioned in
  GitHub releases; the deploy phase reads them without tight coupling or
  requiring redundant, hardcoded, error prone input data.
- **Single source of truth**: GitHub releases serve as the common, authoritative
  source for point-in-time application configuration, providing a shared data
  source to any downstream process (not just deploy automation).

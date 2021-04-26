---
title: Granular Terraform Workspace Naming
date: 2021-04-25
tags:
- terraform
- infrastructure
- cloud
thumbnail: terraform_thumb.png
teaser: Terraform workspaces, their arguable advantages, and some thoughts on naming convention.
---

**Problem**: How can a single [Terraform](https://terraform.io) configuration be used to manage resources across multiple parallel environments or distinct, logical groupings of resources? What are techniques for adequately isolating Terraform actions against one environment or logical resource grouping such that other environments or groupings aren't inadvertently modified?

**Solution**: Sufficiently granular and descriptively named Terraform [_workspaces_](https://www.terraform.io/docs/state/workspaces.html) may help.

## Introduction to Terrraform workspaces

Through the use of [_workspaces_](https://www.terraform.io/docs/state/workspaces.html), Terraform empowers the ability to create multiple, logical groupings of resources -- each associated with its own, independent [state](https://www.terraform.io/docs/state/purpose.html) -- from a single Terraform configuration.

According to the Terraform documentation:

> Each Terraform configuration has an associated [backend](https://www.terraform.io/docs/backends/index.html) that defines how operations are executed and where persistent data such as [the Terraform state](https://www.terraform.io/docs/state/purpose.html) are stored.

> Workspaces are managed with the `terraform workspace` set of commands. To create a new workspace and switch to it, you can use `terraform workspace new`; to switch workspaces you can use `terraform workspace select`; etc.

Despite that named workspaces "allow conveniently switching between multiple instances of a single configuration," the use of workspaces is often overlooked in favor of homegrown patterns. For example, it's common practice to separate Terraform configurations across directories within a code repository, each of which pertains to a named environment (`production`, `development`, etc.), has its own state, and can by applied independently. Similarly, it's also common to adopt the use of a Terraform `var.environment` variable to apply different configuration based on the `var.environment` variable's value.

However, depending on perspective, Terraform's built-in concept of workspaces may offer advantages over homegrown techniques for isolating logical groupings of Terraform resources across environments.

Specifically, a few arguable advantages of workspaces include:

1. Out of the box state isolation
2. Creating and managing infinite new environments is relatively low effort
3. Code DRY-ness and simplicity
4. Simple feature flag capabilities

### 1. Out of the box state isolation

Terraform stores a configuration's remote state in a unique location based on its workspace. In other words, each named workspace has its own, isolated state that is sandboxed from that of other workspaces.

For example, given the following backend state declaration using Amazon S3 as its remote state backend...

```hcl
terraform {
  backend "s3" {
    bucket = "my-team-state"
    key    = "my-service/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Terraform automatically creates a unique, isolated per-workspace `terraform.tfstate` file in S3 at each named workspace-specific path:

```txt
my-team-state/:env/${workspace name}/my-service/terraform.tfstate
```

(If no named workspace is explicitly selected via `terraform workspace select ${workspace}`, Terraform uses the `default` workspace and its corresponding `my-team-state/:env/default/my-service/terraform.tfstate` S3 path.)

Through the use of workspaces, Terraform offers out-of-the-box state isolation; it's not necessary to explicitly declare multiple, per-environment state backend configurations. The use of workspaces also ensure it's less likely the application of one workspace's configuration will impact another workspace's resources and/or state.

### 2. Creating and managing infinite new environments is relatively low effort

By adopting the use of named Terraform workspaces when applying a Terraform configuration, the configuration can be applied against an infinite number of unique, isolated workspaces. In effect, the use of Terraform workspaces makes it less necessary to initially know and declare a finite number of environments -- `production`, `staging`, and `dev`, for example -- and empowers the low effort management of an infinite number of far more granular parallel environments. Most notably in my experience, this may include short-lived and ephemeral environments, as might be helpful in development or when performing A/B tests or canary rollouts.

### 3. Code DRY-ness and simplicity

Additionally, Terraform workspaces arguably reduce the need to repeat Terraform configuration for each environment. Instead, a single Terraform configuration can be applied against multiple workspaces. Through the use of workspaces, it's not necessary to maintain per-environment directories and/or multiple, repetitive, per-environment module instantiations. The use of workspaces also reduces the need to use a `var.environment` variable; `terraform.workspace` can be used intead.

### 4. Simple feature flag capabilities

Terraform workspaces also offer a mechanism through which conditional logic can enable or disable certain infrastructure features or attributes based on the workspace.

For example, the following Terraform only creates a `aws_s3_bucket.my_bucket` resource when applied against the `dev` workspace:

```hcl
resource "aws_s3_bucket" "my_bucket" {
  count  = terraform.workspace == "dev" ? 1 : 0
  bucket = "my-bucket"
}
```

Workspace-based feature flags can be particularly useful when incrementally deploying features across workspaces in a [canary](https://martinfowler.com/bliki/CanaryRelease.html) fashion. By enabling "[NOOP](https://en.wikipedia.org/wiki/NOP_(code))" code changes, workspace-based feature flags may also be helpful when practicing a model of [continuous delivery](https://en.wikipedia.org/wiki/Continuous_delivery) in which small, iterative changes to Terraform configuration are frequently introduced to a repository's main branch and continuously applied.

## Workspace naming

When no explicitly named workspace is selected via `terraform workspace select`, Terraform uses a `default` workspace, as is explained by Terraform's documentation:

> The persistent data stored in the backend belongs to a _workspace_. Initially the backend has only one workspace, called “default”, and thus there is only one Terraform state associated with that configuration.

However, because the use of non-`default` named workspaces enables more granular resource groupings and associated state, a configuration's Terraform actions can safely and easily target subsets of Terraform-managed infrastructure without broader impact. The `terraform.workspace` can also be used -- often in alternative to a `var.environment` -- to uniquely name and tag Terraform-managed resources. This further ensures workspace resource isolation, makes infrastructure self-descriptive, and also makes cloud resources queryable across workspace names.

Ideally, a workspace name should be sufficiently descriptive of the collection of resources associated with the workspace. But how?

## Basic naming convention

In basic scenarios, workspace names mapping to logical environments may suffice. For example:

* `pull-request`
* `dev`
* `staging`
* `prod`

## Advanced naming convention

But what about more advanced scenarios? For example, what about scenarios where a `prod` environment consists of resources across multiple AWS regions, each of which should be applied in isolation? Or even across multiple cloud providers, each of which should be applied in isolation? Or what about when an environment consists of independent `blue` and `green` stacks in the case of a [blue/green deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)? Or an independent [canary stack](https://martinfowler.com/bliki/CanaryRelease.html) in the case of an incremental rampup-style deployment? How can Terraform actions target subsets of complex infrastructure landscapes, ensuring against scenarios where a problematic Terraform action has broad reach beyond its intended field of impact?

For these more advanced landscapes, a logical environment (`prod`, `staging`, etc.) may consist of _multiple_, independent workspaces, each of which maps to its own, independent state. For such scenarios, I've often adopted a more advanced, multi-part workspace-naming convention:

```txt
${env}-${provider}-${region}-${an optional unique identifier if necessary}
```

### What does each part signify?

* `${env}` - the logical environment. For example: prod, staging, dev
* `${provider}` - the cloud provider. For example: aws, openstack, digitalocean
* `${region}` - the region in which the workspace infrastructure lives. For example: us-east-1, us-west-2
* `${an optional unique identifier}` - an optional, more granular unique identifier, if necessary. For example: blue, green, a, b, or even a `${GIT_SHA}`

### Some real world examples:

* `staging-aws-us-west-2`
* `prod-aws-us-east-1`
* `prod-aws-us-east-1-blue`
* `prod-aws-us-east-1-green`
* `prod-aws-us-east-1-5fe7bsa`

## Examples in use

In addition to empowering the ability to execute Terraform actions against a targeted subset of infrastructure without broader impact, sufficiently granular workspace naming also enables per-workspace variables and more targeted configuration differences.

### Per-workspace variable values

For example, consider the following HCL declaring per-workspace AWS RDS instance class values...

```hcl
variable "rds_instance_class" {
  description = "The size of the AWS RDS instance size per workspace"
  type        = map(string)

  default = {
    staging-aws-us-east-1 = "db.t3.micro"
    prod-aws-us-east-1    = "db.m5.8xlarge"
    prod-aws-us-west-2    = "db.m5.8xlarge"
  }
}
```

...which allows the selection of workspace-specific values from a single Terraform configuration:

```hcl
resource "aws_db_instance" "rds" {
  instance_class = var.rds_instance_class[terraform.workspace]
...
```

### Per-env variable values

But isn't that a lot of variable repetition for scenarios where `rds_instance_class` is the same across all `prod-*` workspaces? The use of a [Terraform local](https://www.terraform.io/docs/configuration/locals.html) to select the `env` from the multi-part workspace name enables DRY-ness.

For example, to an extract a `local.env` from the `terraform.workspace`:

```hcl
locals {
  # The 'logical' environment name (prod, staging, dev etc.)
  # taken from the terraform.workspace (prod-aws-us-east-1, for example)
  env = "${split("-", terraform.workspace)[0]}"
}
```

Now, the `rds_instance_class` values can be collapsed to two per-`env` values:

```hcl
variable "rds_instance_class" {
  description = "The size of the AWS RDS instance size per env"
  type        = map(string)

  default = {
    staging = "db.t3.micro"
    prod    = "db.m5.8xlarge"
  }
}
```

In turn, this allows a single Terraform configuration to select and deploy `env`-specific values common to all workspaces in a given `env`:

```hcl
resource "aws_db_instance" "rds" {
  instance_class = var.rds_instance_class[local.env]
...
```

## Summary

In summary, the use of [Terraform workspaces](https://www.terraform.io/docs/language/state/workspaces.html) -- as well as the adoption of a sufficiently granular workspace naming convention -- may help facilitate logical and safe multi-environment Terraform practices and code simplification.

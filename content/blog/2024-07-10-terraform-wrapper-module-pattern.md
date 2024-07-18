---
title: "Terraform Patterns: the wrapper module"
date: 2024-07-10
tags:
- terraform
- terraform-patterns
- iac
thumbnail: terraform5_thumb.png
teaser: An overview of the Terraform wrapper module pattern.
intro: An overview of what I refer to as the Terraform **wrapper module pattern**.
---

## Problem

Internal to your organization, you want to provide engineers simplified, higher
level abstractions for managing AWS resources via [Terraform child modules](/blog/scalable-terraform-patterns-reuse-and-repeatability/#child-modules-generic-composable-recipes).
You could build such modules in-house, but you're wary of the level of effort
required to do so and the resulting maintenance burden, especially considering the existing ecosystem of
well-regarded [community-maintained open source modules](https://registry.terraform.io/browse/modules).
However, many of the [community modules](https://registry.terraform.io/browse/modules)
support input variables and usage patterns that are too broad, require too much
specialized AWS knowledge, and aren't compliant with your organization's "golden
path" standards, guardrails, and supported patterns. You'd like to impose some
specific constraints and simplified interfaces, restricting each module's use
to blessed patterns and easing use for internal users.

## Solution

Leverage the **wrapper module pattern**; create minimal, higher level modules
that wrap community-maintained modules and impose a more limited internal interface.

## Example

As a contrived example, consider CloudPosse's [S3 Bucket module](https://registry.terraform.io/modules/cloudposse/s3-bucket/aws/latest). The module
is well-maintained, highly regarded, and has a fairly mature development-and-release
lifecycle backed by CI/CD and automated tests. However, out of the box, the module
accepts over 58 input variables, perhaps making it a bit _too_ flexible for some
organizations' internal standards.

By wrapping its use in a higher level child module akin to the following, a
more limited interface can be imposed, exposing _only_ the ability to specify a
bucket name that conforms to internal governance requirements:

```terraform
variable "name" {
  type        = string
  description = "The S3 bucket name. The 'my-company-' prefix will be automatically added if it's not already present."  

  validation {
    condition     = var.name != null && var.name != "" && !strcontains(var.name, "_")
    error_message = "The name value must be specified and cannot include '_' characters"
  }
}

locals {
  prefix = "my-company-"

  prefixed_name = startswith(var.name, local.prefix) ? var.name : "${local.prefix}${var.name}"
}

module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "4.2.0"

  name = local.prefixed_name
}
```

<div class="note">
  <p>👋 NOTE: The example above is a bit contrived, has debatable real-world utility, and isn't intended to be emulated verbatim; it's merely an illustration of the general idea of the wrapper module pattern. Don't take this too literally.</p>
</div>

As a result, the bulk of complexity lives within the [S3 Bucket
module](https://registry.terraform.io/modules/cloudposse/s3-bucket/aws/latest);
the challenging maintenance is distributed throughout the upstream open source community and
the meaty automated testing and release management continues to live at [cloudposse/terraform-aws-s3-bucket](https://github.com/cloudposse/terraform-aws-s3-bucket).
You've avoided reinventing the wheel. Plus, if ever it's necessary, the `cloudposse/s3-bucket/aws`
module can be swapped out for something else without disrupting your internal
module's interface.

(Although, depending on needs and complexity, it may still be worthwhile to maintain your own CI/CD, automated testing validating your wrapper module's integration with the upstream child module, and an internal semantic versioning release process. Still, in my experience, the wrapper module pattern offers a decent efficiency gain in many contexts.)

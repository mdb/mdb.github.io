---
title: "Terraform: self-validating plan-time permissions checks"
date: 2025-03-21
tags:
- terraform
- iac
thumbnail: texture2_thumb.png
teaser: How can a Terraform configuration test whether it has sufficient access to do its own work?
---

## Problem

Your Terraform module uses the [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) provider. In CI/CD, the `plan` associated with a GitHub pull request passes. However, after merging the pull request,
the full `apply` fails; the IAM role used by the AWS provider lacks sufficient permissions.

How can you "shift left" and discover such problems earlier in the CI/CD
pipeline at `plan` time, before a pull request is merged?

## Solution

Leverage the [iam_principal_policy_simulation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_principal_policy_simulation) data source; test whether the utilized IAM role has the necessary access to do its own work.

## Example

The following configuration ensures `terraform plan` fails if the utilized role
does not have sufficient s3 permissions:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_principal_policy_simulation" "s3_object_access" {
  action_names = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
  ]
  policy_source_arn = data.aws_iam_session_context.current.issuer_arn
  resource_arns     = ["arn:aws:s3:::*"]

  lifecycle {
    postcondition {
      condition     = self.all_allowed
      error_message = <<EOT
        "${data.aws_iam_session_context.current.issuer_arn} does not have sufficient permissions to manage ${join(", ", self.resource_arns)}.
      EOT
    }
  }
}
```

A passing `terraform plan`:

```
terraform plan \
  -out plan.out
data.aws_caller_identity.current: Reading...
data.aws_caller_identity.current: Read complete after 0s [id=REDACTED]
data.aws_iam_session_context.current: Reading...
data.aws_iam_session_context.current: Read complete after 0s [id=arn:aws:sts::REDACTED:assumed-role/AWSReservedSSO_REDACTED_REDACTED/REDACTED@REDACTED.com]
data.aws_iam_principal_policy_simulation.s3_object_access: Reading...
data.aws_iam_principal_policy_simulation.s3_object_access: Read complete after 0s [id=-]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

Alternatively, a failing `terraform plan` would error:

```
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Resource postcondition failed
│
│   on main.tf line 31, in data "aws_iam_principal_policy_simulation" "s3_object_access":
│   31:       condition     = self.all_allowed
│     ├────────────────
│     │ self.all_allowed is false
│
│ "arn:aws:iam::REDACTED:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_REDACTED_REDACTED
│ does have sufficient permissions to manage arn:aws:s3:::*.
```

## Alternative implementation

Alternatively, you could leverage a Terraform [check](https://developer.hashicorp.com/terraform/language/checks):

```terraform
...
check "permissions" {
  data "aws_iam_principal_policy_simulation" "s3_object_access" {
    action_names = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    policy_source_arn = data.aws_iam_session_context.current.issuer_arn
    resource_arns     = ["arn:aws:s3:::*"]
  }

  assert {
    condition     = data.aws_iam_principal_policy_simulation.bucket_object.all_allowed
    error_message = <<EOT
      "${data.aws_iam_session_context.current.issuer_arn} does not have sufficient permissions to manage ${join(", ", data.aws_iam_principal_policy_simulation.bucket_object.resource_arns)}."
    EOT
  }
}
```

## Bonus

Perhaps self-evident, but the technique offers UX benefits when baked into [published child modules](https://developer.hashicorp.com/terraform/language/modules#the-root-module);
a module can vet an instantiation's permissions as part of its own `plan` phase.

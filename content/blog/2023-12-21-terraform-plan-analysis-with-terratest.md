---
title: "Automated Terraform Plan Analysis With Terratest"
date: 2023-12-21
tags:
- terraform
- terratest
- iac
thumbnail: some_cars_thumb.png
teaser: "How can terratest be used to automate Terraform plan analysis?"
---

_How can [terratest](https://terratest.gruntwork.io/) be used to automate [Terraform plan](https://developer.hashicorp.com/terraform/cli/commands/plan) analysis?_

## Problem

You want to automate [Terraform
plan](https://developer.hashicorp.com/terraform/cli/commands/plan) analysis in
CI/CD, offsetting some of the manual toil associated with plan assessment. Tools
like [OPA](https://mikeball.info/blog/terraform-plan-validation-with-open-policy-agent/) offer
policy-as-code solutions, but your team prefers to write Go.

## Solution

Usually, [terratest](https://terratest.gruntwork.io/) is leveraged as a tool for
authoring Terraform end-to-end tests that make post-`terraform apply` assertions on
the correctness of the resulting infrastructure.

However, `terratest` can also be used to programmatically analyze Terraform plan
output, effectively offering a Go-based alternative to tools like OPA and similar policy-as-code tools.

## Use case examples

* fail pull request CI if a Teraform change introduces a destructive action
  against a production-critical resource
* verify the correctness of the planned DNS record modifications during a Terraform-orchestrated
  DNS-based blue/green deployment
* ensure an ECR repository marked for destruction does not home OCI images used
  by active ECR task definitions
* "shift left" on detecting problematic PagerDuty Terraform edits, as some
  [terraform-provider-pagerduty](https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs) errors don't reveal themselves
  at `plan` time; they only occur during an attempt to `apply`. For example:

  ```
  Error: DELETE API call to https://api.pagerduty.com/users/12345 failed 400 Bad Request. Code: 0, Errors: [The user cannot be deleted as they have 1 incident. Please resolve the following incident to continue.], Message:
  ```

  In such instances, a `terratest` test of the Terraform plan produced by a pull
  request CI build can use the PagerDuty API to evaluate whether a user-to-be-deleted
  is assigned open incidents, in advance of merging the pull request and applying the plan.

## Example

[terratest-tf-plan-demo](https://github.com/mdb/terratest-tf-plan-demo) offers an
example of how `terratest` could be integrated with a CI/CD pipeline. Its
`README.md` offers detailed explanation of its [GitHub Actions CI/CD pipeline](https://github.com/mdb/terratest-tf-plan-demo#github-actions),
as well as [instructions](https://github.com/mdb/terratest-tf-plan-demo#run-terratest-tf-plan-demo-locally) for running the tests locally.

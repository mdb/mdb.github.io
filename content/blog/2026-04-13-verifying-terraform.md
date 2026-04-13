---
title: "Verifying and validating Terraform: techniques for testing infrastructure-as-code"
date: 2026-04-13
tags:
- terraform
- terraform-patterns
- iac
- testing
thumbnail: terraform3_thumb.png
teaser: An overview of techniques for testing Terraform, from linting to end-to-end testing.
display_toc: true
intro: |
  Beyond `terraform plan`-ing and manually reviewing plan output, how else can
  Terraform code be validated and verified?

  Written primarily for Terraform newcomers, the following offers a
  non-exhaustive overview of some techniques and options for testing Terraform,
  and my take on when and where each best plugs into the infrastructure-as-code
  development and CI/CD lifecycle.
---

## Static analysis & linting

* **What:** Style violations, formatting inconsistencies, common
anti-patterns.
* **When:** Pre-plan. Often as a pre-commit hook or early CI step.

The simplest verification: does the code satisfy style and structural
preferences?

Examples...

### terraform fmt

Exit non-zero if Terraform code is not properly formatted:

```sh
terraform fmt \
  -recursive \
  -check
```

### tflint

Tools like [tflint](https://github.com/terraform-linters/tflint) go further: catch
provider-specific issues, deprecated syntax, and enforcing naming conventions.
Combined with the
[tflint-ruleset-aws](https://github.com/terraform-linters/tflint-ruleset-aws)
(or equivalent provider-specific rulesets), it can flag invalid instance types,
nonexistent AMIs, and similar provider-aware problems.

```sh
tflint --recursive
```

## Input variable validation

* **What:** Invalid input values before they cause downstream failures.
* **When:** Plan-time.

Terraform's native [input variable validation](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation)
conditions let a module define constraints on its own inputs:

```terraform
variable "ami" {
  type        = string
  description = "The Amazon machine image (AMI) ID to use."

  validation {
    condition     = length(var.ami) > 4 && substr(var.ami, 0, 4) == "ami-"
    error_message = "The ami value must be a valid AWS AMI ID starting with \"ami-\"."
  }
}

variable "environment" {
  type        = string
  description = "The target environment."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

This is particularly valuable in [child modules](https://developer.hashicorp.com/terraform/language/modules#child-modules);
the module itself enforces its own contract.

## Lifecycle preconditions and postconditions

* **What:** Assumptions about the environment (preconditions) and
guarantees about the result (postconditions).
* **When:** Plan-time (preconditions), apply-time (postconditions).

[Custom conditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#preconditions-and-postconditions)
let you embed assertions directly into resource and data source lifecycle blocks:

```terraform
data "aws_ami" "app" {
  most_recent = true

  filter {
    name   = "name"
    values = ["my-app-*"]
  }
}

resource "aws_instance" "app" {
  instance_type = "t3.micro"
  ami           = data.aws_ami.app.id

  lifecycle {
    precondition {
      condition     = data.aws_ami.app.architecture == "x86_64"
      error_message = "The AMI must use the x86_64 architecture."
    }

    postcondition {
      condition     = self.public_ip != ""
      error_message = "The instance must receive a public IP."
    }
  }
}
```

Preconditions and postconditions are _blocking_: a failure halts the plan or
apply. This distinguishes them from check blocks (discussed below), which only
warn.

[Terraform: self-validating plan-time permissions checks](/blog/terraform-self-validating-plan-time-permissions-checks/)
demonstrates how postconditions on data sources can "shift left" on permissions
validation, catching IAM issues at `plan` time rather than `apply` time.

Takeaway: Use preconditions to validate assumptions your configuration depends on.
Use postconditions to assert guarantees about the resources you create.

## `terraform test` with mock providers

* **What:** Catch logic errors in module behavior without creating real
infrastructure.
* **When:** Local development, CI, pre-merge. No cloud credentials needed.

Beginning in Terraform v1.7, [mock providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
allow `terraform test` to exercise a configuration without calling any real
provider APIs. Mock providers generate fake data for computed attributes while
accepting user-provided values for everything else.

Consider a module that constructs a resource name from inputs:

```terraform
# modules/naming/main.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  name = var.environment == "prod" ? "${var.project}-${var.environment}" : "${var.project}-dev"
}

output "name" {
  value = local.name
}
```

A test with a mock provider verifies the logic in isolation:

```hcl
# modules/naming/tests/unit.tftest.hcl
run "name_format" {
  command = plan

  variables {
    project     = "myapp"
    environment = "prod"
  }

  assert {
    condition     = output.name == "myapp-prod"
    error_message = "Expected name 'myapp-prod', got '${output.name}'"
  }
}
```

For configurations that reference provider-managed resources, mock providers fill
in computed values so the plan can complete:

```hcl
# tests/unit.tftest.hcl
mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::test-bucket"
    }
  }
}

run "bucket_tags" {
  command = plan

  variables {
    bucket_name = "test-bucket"
    environment = "dev"
  }

  assert {
    condition     = aws_s3_bucket.main.tags["Environment"] == "dev"
    error_message = "Environment tag not set correctly."
  }
}
```

`override_resource`, `override_data`, and `override_module` allow you to control
specific values with finer granularity.

Takeaway: Mock-based tests are fast and have no dependency on real cloud
provider APIs. They're good for validating module logic, conditional expressions,
`for_each` behavior, and output correctness. They can't verify the infrastructure
actually works.

## `terraform test` with real providers

* **What:** End-to-end correctness of the provisioned infrastructure.
* **When:** CI, typically against a sandbox or development environment. Requires credentials.

When `command = apply` (the default) is used without mocks, `terraform test`
provisions real infrastructure, makes assertions against it, and tears it down:

```hcl
# tests/e2e.tftest.hcl
variables {
  environment = "test"
}

run "creates_bucket" {
  variables {
    bucket_name = "my-e2e-test-bucket"
  }

  assert {
    condition     = aws_s3_bucket.main.bucket == "my-e2e-test-bucket"
    error_message = "Bucket name does not match."
  }

  assert {
    condition     = aws_s3_bucket.main.versioning[0].enabled == true
    error_message = "Versioning should be enabled."
  }
}
```

Helper modules can manage test fixtures:

```hcl
run "setup_vpc" {
  module {
    source = "./testing/setup"
  }
}

run "deploy_into_vpc" {
  variables {
    vpc_id = run.setup_vpc.vpc_id
  }

  assert {
    condition     = aws_instance.app.subnet_id != ""
    error_message = "Instance was not placed in a subnet."
  }
}
```

`terraform test` automatically cleans up resources automatically when all run
blocks complete (or when a test fails).

### Root modules vs. child modules

_Child_ module tests verify the [child module](https://mikeball.info/blog/scalable-terraform-patterns-reuse-and-repeatability/#child-modules-generic-composable-recipes)'s own interface and behavior in
isolation, outside its usage among consumers. In my experience, they typically
run as part of the child module's independent CI/CD lifecycle, outside that
module's use amongst consumers:

```
modules/vpc/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    ├── unit.tftest.hcl # mock providers; fast
    └── e2e.tftest.hcl  # real providers; slower
```

_Root_ module tests verify the [root module](https://developer.hashicorp.com/terraform/language/modules) composition: that child modules
are wired together correctly, that workspace-specific variable values produce the
expected configuration, and that the integrated system functions as intended:

```
deployments/api/
├── main.tf
├── variables.tf
├── terraform.tfvars
└── tests/
    └── unit.tftest.hcl
    └── integration.tftest.hcl
```

Typically, I recommend investing more in child module tests -- these
verify the fundamental "building blocks" used by root modules.

Takeaway: Real-provider tests give the highest confidence but are the slowest and most
expensive to run. Use them to verify the things mock tests can't: actual
provider behavior, IAM interactions, network connectivity, and resource
dependencies.

## Policy-as-code

* **What:** catch governance violations, security misconfigurations,
compliance drift, risky operations, cost implications, destructive changes to
critical resources
* **When:** Post-plan, pre-apply. Often in a dedicated CI step analyzing
the plan JSON.

Policy-as-code tools evaluate a Terraform plan against codified rules. Unlike
input validation (which a module author embeds), policy-as-code can be maintained
centrally by a platform or security team and enforced across all Terraform pipelines.
Or, it can be module-specific, and impose safeguards prohibiting plan-specific actions,
such as the planned deletion of production-critical infrastructure.

### Open Policy Agent (OPA)

[OPA](https://www.openpolicyagent.org/) evaluates [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/)
policies against Terraform plan JSON. The workflow:

```sh
# Generate plan JSON
terraform plan -out=plan.binary
terraform show -json plan.binary > plan.json

# Evaluate policies
opa eval \
  --data policies/ \
  --input plan.json \
  "data.terraform.analysis.deny" \
  --fail
```

An example policy preventing public S3 buckets:

```rego
package terraform.analysis

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  change := resource.change.after

  not change.block_public_acls
  msg := sprintf("S3 bucket %s must block public ACLs", [resource.address])
}
```

OPA policies can also be tested independently via `opa test`, giving confidence
that the policies themselves are correct (see [Terraform Plan Validation With
Open Policy Agent](/blog/terraform-plan-validation-with-open-policy-agent/) for
a full walkthrough).

Tools like [conftest](https://www.openpolicyagent.org/ecosystem/entry/conftest)
offer offer higher level convenience utilities on top of OPA.

### Checkov

[Checkov](https://www.checkov.io/) is another popular policy-as-code tool; it
offers hundreds of built-in policies for common cloud misconfigurations out of
the box:

```sh
checkov -d . --framework terraform
```

Checkov can also scan plan JSON for runtime-aware analysis, and supports custom
policies when the built-in rules don't cover your requirements.

### Native Terraform vs. external policy tools

Native Terraform validation (input validation, preconditions) is simpler and
lives alongside the code it protects. External tools like OPA and Checkov enable
centralized governance across many Terraform pipelines and can analyze
properties of the plan JSON that native Terraform offers no interface for
testing (e.g., "this plan must not destroy more than N resources" or "this plan
must not modify resources tagged `critical`").

The two approaches are complementary: native validation for module-level
contracts, external policy for organization-level and/or operation-specific guardrails.

Beyond strict pass/fail policy checks, the Terraform plan JSON can be analyzed
programmatically for risk assessment and decision support. This analysis doesn't
necessarily _gate_ -- it might surface warnings, annotate pull requests, or flag
changes for additional review. Alternatively, it might be used to auto-approve
pull requests deemed acceptable.

Takeaway: Policy-as-code helps enforce standards across teams. Adopt it when you
need governance beyond what any single module author can natively embed in Terraform.

## Assistive analysis

* **What:** Risky operations, cost implications, destructive changes to
critical resources.
* **When:** Post-plan, pre-merge or pre-apply.

Terraform CI/CD pipelines can also be augmented with with assistive, informational tooling:

- [tf-summarize](https://github.com/dineshba/tf-summarize) generates a
  human-readable summary of planned changes
- cost estimation tools (like [Infracost](https://www.infracost.io/)) surface
  the financial impact of a change
- custom scripts that annotate PRs with the count of creates, updates, and
  destroys
- AI-driven plain text plan explanation

Programmatic plan analysis fills the gap between automated policy gates and
manual review. Use it to surface risk, estimate impact, and give authors and
reviewers better context.

## Check blocks

* **What:** make ongoing infrastructure health assertions.
* **When:** Every plan and apply -- but failures only _warn_, they don't block.

Terraform [check blocks](https://developer.hashicorp.com/terraform/language/checks)
are a distinct verification mechanism: they're assertions about your
infrastructure that are decoupled from any specific resource lifecycle. A failing
check produces a warning, not an error.

```terraform
check "api_health" {
  data "http" "api" {
    url = "https://${aws_lb.api.dns_name}/healthz"
  }

  assert {
    condition     = data.http.api.status_code == 200
    error_message = "API health check returned ${data.http.api.status_code}"
  }
}
```

Check blocks can define their own scoped data sources (as shown above) that
aren't accessible elsewhere in the configuration. This makes them useful for
verifying external state without polluting the module's resource graph.

### Checks vs. postconditions

| | Postconditions | Checks |
|---|---|---|
| **Scope** | Tied to a specific resource | Independent of any resource |
| **On failure** | Blocks the plan/apply | Warns but continues |
| **Use case** | "This resource _must_ have property X" | "The system _should_ be in state Y" |

### When to use checks

- Verify that a deployed service is responding after apply
- Assert that a certificate is valid or not near expiry
- Validate assumptions about external systems your configuration depends on

Takeaway: Checks often operate as a post-apply safety net. They surface drift and environmental
issues as warnings on every run without blocking operations. Pair them with
postconditions: postconditions for hard guarantees, checks for soft
assertions and visibility.

## Putting it together

| Layer | When | What it catches |
|---|---|---|
| `fmt`, `tflint` | pre-plan | Style, syntax, structural issues |
| Input validation | plan-time | Bad input values |
| Preconditions/postconditions | plan/apply-time | Environmental assumptions, resource guarantees |
| `terraform test` (mocks, child modules) | pre-plan | Logic errors, output correctness |
| `terraform test` (real, child modules) | pre-plan | End-to-end infrastructure correctness |
| Policy-as-code | post-plan | Governance, security, compliance violations, risk, cost, destructive change warnings |
| Assistive analysis tooling | post-plan | Risk, cost, intent/impact validation |
| Check blocks | apply-time | Ongoing infrastructure health |

## Further reading

- [Terraform custom conditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions)
- [Terraform tests](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform mock providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
- [Terraform check blocks](https://developer.hashicorp.com/terraform/language/checks)
- [Open Policy Agent Terraform support](https://www.openpolicyagent.org/docs/latest/terraform/)
- [Automated Terraform Plan Analysis With Terratest](/blog/automated-terraform-plan-analysis-with-terratest/)
- [Terraform Plan Validation With Open Policy Agent](/blog/terraform-plan-validation-with-open-policy-agent/)
- [Terraform: self-validating plan-time permissions checks](/blog/terraform-self-validating-plan-time-permissions-checks/)

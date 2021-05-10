---
title: Terraform Plan Validation With Open Policy Agent
date: 2021-05-09
tags:
- opa
- terraform
- open policy agent
thumbnail:
teaser: Automating Terraform plan analysis with Open Policy Agent
---

_A pattern for automatting Terraform plan analysis using Open Policy Agent._

## Problem

Your CI/CD pipeline performs a Terraform [plan](https://www.terraform.io/docs/cli/commands/plan.html) prior to executing a Terraform [apply](https://www.terraform.io/docs/cli/commands/apply.html). The CI/CD pipeline gates on the Terraform plan, such that team members can manually review its output for unwanted, problematic, and/or destructive resource changes. While the manual plan review helps ensure against the application of changes that could negatively impact systems' availability, the manual analysis is tedious and error prone.

Could aspects of the Terraform plan analysis be automated? Could such automation help expedite reviews and protect against errors? [HashiCorp Sentinel](https://www.hashicorp.com/sentinel) offers a relevant policy-as-code solution, but it's a paid product. What free and open source Terraform policy-as-code tooling exists?

## Solution

[Open Policy Agent](https://www.openpolicyagent.org/) offers a flexible, multi-purpose policy-as-code framework. Its [Terraform support](https://www.openpolicyagent.org/docs/latest/terraform/) enables the codification of rules and expectations pertaining to Terraform plans, in effect providing a toolset through which Terraform plan analysis and checks can be automated in CI/CD pipelines.

## Example

For the purposes of simplicity, consider a simple -- though somewhat contrived -- example. An apply of the following Terraform configuration creates a `greet.sh` script that `echo`s the `var.greeting`'s value:

```hcl
variable greeting {
  description = "The greeting to echo from the greet.sh script"
  value       = "hello"
}

data "template_file" "greeting" {
  template = <<-EOT
  #/bin/bash

  echo "${var.greeting}"
  EOT
}

resource "local_file" "greeting" {
  content  = data.template_file.greeting.rendered
  filename = "${path.module}/greeting.sh"
}
```

By default, this configuration creates a `greet.sh` file using the default `var.greeting` value of `"hello"`:

```sh
#!/bin/bash

echo "hello"
```

When the default `var.greeting` value is used, a `terraform plan` of the configuration reveals the following:

```terraform
terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.greeting will be created
  + resource "local_file" "greeting" {
      + content              = <<-EOT
            #/bin/bash

            echo "hello"
        EOT
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./greeting.sh"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

How can [OPA](https://openpolicyagent.org) be used to codify a policy guarding against unwanted configuration? For example, how could OPA be used to ensure that `var.greeting` never has an inappropriate greeting value, such as `"goodbye"`? How could OPA's [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) policy language express such a policy?

The following `policy.rego` file offers an example:

```txt
package terraform.analysis
import input as tfplan

has_acceptable_greeting {
  greeting := input.variables["greeting"]

  contains(greeting.value, "goodbye") != true
}
```

The `policy.rego` policy accepts a [Terraform plan JSON](https://www.terraform.io/docs/internals/json-format.html) as input, analyzes the value of the plan JSON's `var.greeting`, and contain a `has_acceptable_greeting` expression that checks if the plan JSON's `var.greeting` value is `"goodbye"`. The policy can be evaluated 

The policy expressed in the `policy.rego` file can be evaluated via the `opa` CLI (See the [OPA website's installation instructions](https://www.openpolicyagent.org/docs/latest/#running-opa))...

First, execute a `terraform plan` and save the output to a `tf-plan.binary` file:

```txt
terraform plan \
  --out tf-plan.binary
```

Next, use `terraform show` to convert the `tf-plan.binary` to a `tf-plan.json` file:

```txt
terraform show \
  -json tf-plan.binary > tf-plan.json
```

Finally, execute `opa eval` against the `has_acceptable_greeting` expression, specifying the `policy.rego` and `tf-plan.json` as the `--data` and `--input`, respectively, and also denoting `--fail` to exit nonzero if `has_acceptable_greeting` identifies a policy violation:

```txt
opa eval \
  --data policy.rego \
  --input tf-plan.json \
  "data.terraform.analysis.has_acceptable_greeting" \
  --fail

{
  "result": [
    {
      "expressions": [
        {
          "value": true,
          "text": "data.terraform.analysis.has_acceptable_greeting",
          "location": {
            "row": 1,
            "col": 1
          }
        }
      ]
    }
  ]
}
```

Note `opa eval`'s successful exit code; this indicates the plan JSON conforms to the codified `policy.rego` policy.

To check that `policy.rego`'s `has_acceptable_greeting` correctly identifies unacceptable `var.greeting` values, pass a `-var greeting=goodbye` during `terraform plan`:

```txt
terraform plan \
  -var 'greeting=goodbye' \
  --out tf-plan.binary
```

Convert the new `tf-plan.binary` to a `tf-plan.json`:

```txt
terraform show \
  -json tf-plan.binary > tf-plan.json
```

Execute `opa eval` against the new `tf-plan.json`; note its nonzero exit code indicating the plan JSON violates the codified `policy.rego` policy:

```txt
opa eval \
  --data policy.rego \
  --input tf-plan.json \
  "data.terraform.analysis.has_acceptable_greeting" \
  --fail
{}
```

## More advanced use cases

While the `has_acceptable_greeting` is example is simple and fairly contrived, more sophisticated real world policies might...

* ensure AWS security groups never allow ingress on port 22
* protect against destructive actions on critical resources
* verify the intended DNS record modifications during a Terraform-orchestrated DNS-based [blue/green deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)

## Policy tests

In addition to offering a policy-as-code framework, OPA can also verify the correctness of your policies via tests of the policies themselves.

For example, test cases exercising the `policy.rego`'s `has_acceptable_greeting` policy can live in a `policy_test.rego` file:

```txt
package terraform.analysis

test_acceptable_greeting {
  has_acceptable_greeting with input as {"variables": {"greeting": {"value": "hello"}}}
}

test_inacceptable_greeting {
  not has_acceptable_greeting with input as {"variables": {"greeting": {"value": "goodbye"}}}
}

test_inacceptable_verbose_greeting {
  not has_acceptable_greeting with input as {"variables": {"greeting": {"value": "foo goodbye bar"}}}
}
```

These test cases make assertions on on `has_acceptable_greeting`'s behavior given various Terraform plan JSON scenarios.

To execute the tests:

```txt
opa test . --verbose
data.terraform.analysis.test_acceptable_greeting: PASS (362.109µs)
data.terraform.analysis.test_inacceptable_greeting: PASS (124.44µs)
data.terraform.analysis.test_inacceptable_verbose_greeting: PASS (105.393µs)
--------------------------------------------------------------------------------
PASS: 3/3
```

## Bonus: GitHub Actions

[github.com/mdb/terraform-opa-demo](https://github.com/mdb/terraform-opa-demo) demonstrates a complete working example of the above-described techniques with the relevant sequence of commands codified as `Makefile` targets. View its [Actions](https://github.com/mdb/terraform-opa-demo/actions) to see how OPA might work in a [GitHub Actions](https://github.com/features/actions) CI/CD pipeline, as established by its [.github/workflows/main.yml](https://github.com/mdb/terraform-opa-demo/blob/main/.github/workflows/main.yml) GitHub Actions configuration.

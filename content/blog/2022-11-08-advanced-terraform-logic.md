---
title: Advanced Terraform Logic
date: 2022-11-08
tags:
- terraform
- grafana
- platform engineering
thumbnail: terraform2_thumb.jpg
teaser: A case study illustrating Terraform techniques for expressing moderately complex business logic.
---

_Critics argue [Terraform](https://terraform.io) is limiting and doesn't adequately enable the expression of complex logic. While imperfect, Terraform does indeed often accommodate moderately complex logic. As a reference example, the following illustrates how Terraform constructs such as `for_each`, `for`/`in`, `if`, `try`, various [functions](https://developer.hashicorp.com/terraform/language/functions), and custom `local` data structures can be used to successfully satisfy a relatively logic-intensive use case._

_As a bonus, the reference example also teases some broader techniques for automating platform engineering across an organization._

[github.com/mdb/terraform-advanced-logic-demo](https://github.com/mdb/terraform-advanced-logic-demo) homes the source code referenced throughout this post.

## Problem

For example's sake, imagine a contrived scenario:

You'd like to use Terraform to automate the management of [Grafana](https://grafana.com/) folders and dashboards for each of a GitHub organization's microservices.

A few assumptions driving the implementation:

1. the GitHub organization consists of multiple git repositories
1. each git repository may home zero or many microservices in its default branch
1. each microservice has a corresponding `Dockerfile`
1. the `Dockerfile`'s directory name indicates its microservice name
1. each git repository should have a corresponding Grafana folder following the naming convention of `${github_org}_${git_repository}`
1. each microservice should have a corresponding Grafana dashboard following the naming convention of `${github_org}_${git_repository}_${microservice_name}`; the dashboard should live in the corresponding `${github_org}_${git_repository}` Grafana folder
1. if a microservice's `Dockerfile` is homed in a git repository's root (and not a subdirectory), the Grafana dashboard should be named `${github_org}_${git_repository}`
1. git repositories may feature a dot (`.`) in their name, though Grafana folders and dashboards should not feature a dot in their name
1. archived git repositories should be ignored
1. git repositories that have no default branch should be ignored
1. in addition to being driven dynamically by `Dockerfile`s homed in git repositories (as described above), the automation should also support creating additional Grafana folders and dashboards from a static, hard-coded list provided via a YAML file

While the above-listed requirements are a bit contrived, they offer an example scenario through which some more advanced, less obvious Terraform features can be exercised and demonstrated.

## Solution overview

Before examining its code, here's an overview of some key aspects of the implementation:

* The [GitHub Terraform provider](https://registry.terraform.io/providers/integrations/github/latest/docs)'s data sources enable querying GitHub repositories via Terraform
* In particular, the [`github_tree` data source](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/tree) enables querying and analyzing repository contents, such as the existence of `Dockerfile`s and those files' paths
* `for_each` and `for`/`in` enables looping and data transformation
* `if` enables conditional logic
* `locals` enable building custom data structures catering to the nuanced business requirements
* `try` enables gracefully handling errors and falling back to reliable default Terraform expressions if/when errors occur
* various other Terraform functions such as `distinct`, `flatten`, `replace`, `lower`, `endswith`, `split`, `length`, `concat` further enable business logic, functionality, and formatting
* The [Grafana Terraform provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs) enables the management of Grafana folders and dashboards via Terraform

## Solution code

`provider.tf` configures the necessary providers. Note that...

* For demonstration purposes, the configuration targets a local Grafana using hard-coded authentication credentials. In a real-world scenario, the configuration would likely target a real, remote Grafana URL, and would not expose hard-coded credentials.
* For demonstration purposes, the configuration does not configure a [remote state backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration), though a real-world configuration likely would.
* The GitHub provider is configured to target the GitHub organization specified as `local.owner` (stay tuned on this...).

`provider.tf`:

{{< gist mdb e14382aded52a7890203ba9cf3b0610d "provider.tf" >}}

`data.tf` uses data sources provided by the GitHub provider to query GitHub repositories via the GitHub API and, ultimately, fetch a file tree representing the files in each repository's default branch across the targeted GitHub organization.

`data.tf`:

{{< gist mdb e14382aded52a7890203ba9cf3b0610d "data.tf" >}}

`locals.tf`...

* specifies [vinyldns](https://github.com/vinyldns) as the targeted GitHub organization (The use of the `vinyldns` organization is fairly arbitrary and chosen largely because its repositories feature `Dockerfile`s homed in root and non-root directories, thus simulating some of the above-listed assumptions driving the contrived example)
* exercises logic building a `local.grafana_dashboards` data structure homing the properly formatted dashboard names and corresponding Grafana folder, themselves ultimately driven by the directory location of `Dockerfile`s across [vinyldns](https://github.com/vinyldns) git repositories, and supplemented by a static list defined in an `additional_dashboards.yaml` file
* exercises logic building a `local.grafana_folders` data structure homing a deduplicated list of _just_ the Grafana folder names

`locals.tf`:

{{< gist mdb e14382aded52a7890203ba9cf3b0610d "locals.tf" >}}

`additional_dashboards.yaml`:

{{< gist mdb e14382aded52a7890203ba9cf3b0610d "additional_dashboards.yaml" >}}

...and, finally, `grafana.tf` enables the creation of...

* a Grafana folder for each item in `local.grafana_folders`
* a Grafana dashboard whose name and title correspond to the `dashboard` attribute of each object in the `local.grafana_folders`

`grafana.tf`:

{{< gist mdb e14382aded52a7890203ba9cf3b0610d "grafana.tf" >}}

Note that...

* In this example, the Grafana dashboard JSON is deliberately simple. However, Terraform offers options for templating more complex Grafana JSON too, either via Terraform's own [templatefile function](https://developer.hashicorp.com/terraform/language/functions/templatefile) or even via [jsonnet](https://jsonnet.org/), perhaps in concert with [grafonnet](https://grafana.github.io/grafonnet-lib/) and even a [Terraform jsonnet provider](https://registry.terraform.io/providers/alxrem/jsonnet/latest/docs), [grizzly](https://grafana.github.io/grizzly/), or other templating technologies.
* The [Grafana Terraform provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs) offers resources for managing many other aspects of Grafana too, such as teams, API keys, etc. A real-world example might manage additional Grafana resources via Terraform. For example, Terraform could manage the creation of a unique Grafana API key for each git repository in the targeted organization, and seed that key in a corresponding `GRAFANA_API_KEY` [GitHub Actions secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) in each repository. This would then enable the repositories' GitHub Actions workflows to programmatically interact with Grafana, thereby empowering further platform automation capabilities.

## Summary, Disclaimers, etc.

Again, the above-described example is somewhat contrived. In particular, because the implementation uses GitHub provider data sources to dynamically drive the dashboards and folder names, each `terraform apply` invocation could yield differing results if/when modifications to the underlying git repositories and/or their `Dockerfile`s are performed between `apply` invocations. For example...

* When new git repositories and microservices are created, a subsequent `terraform apply` is necessary to create their corresponding Grafana folders and dashboards. If necessary, this could be orchestrated via automation that invokes `terraform apply` in response to relevant [GitHub organization webhook events](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads).
* When git repositories and/or microservices are deleted, a subsequent `terraform apply` could inadvertently result in the corresponding Grafana resources' destruction. If undesired, this could be mitigated via the use of the [prevent_destroy](https://developer.hashicorp.com/terraform/tutorials/state/resource-lifecycle#prevent-resource-deletion) lifecyle argument, or by hardcoding such dashboards and folders in the `additional_dashboards.yaml` file. Alternatively, the use of the GitHub provider data sources could be reevaluated or evolved to better account real-world needs.

The above-described example is merely intended to showcase a few Terraform capabilities, and to inspire ideas. In addition to demonstrating semi-advanced logic, the configuration also teases some broader ideas for automating platform onboarding across an organization: While the example focuses largely on Grafana resources, the pattern could be applied to bootstrap other aspects of platform engineering across other non-Grafana providers For example...

* PagerDuty configurations
* artifact repositories
* Vault secrets
* AWS resources, or even AWS account provisioning
* Kubernetes namespaces and other Kubernetes resources
* etc.

See [github.com/mdb/terraform-advanced-logic-demo](https://github.com/mdb/terraform-advanced-logic-demo) for the complete Terraform configuration.

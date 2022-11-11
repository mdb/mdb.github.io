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

_Critics argue [Terraform](https://terraform.io) is limiting and doesn't adequately enable the expression of complex logic in HCL. While imperfect, Terraform does indeed often accommodate moderately complex logic. As a reference example, the following illustrates how Terraform constructs such as `for_each`, `for`/`in`, `if`, `try`, various [functions](https://developer.hashicorp.com/terraform/language/functions), and custom `local` data structures can be used to successfully satisfy a relatively logic-intensive use case._

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
* In particular, the [`github_tree` data source](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/tree) enables querying and analyzing repository contents, such as the existence of `Dockerfile`s and those files' directory names
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
* The GitHub provider is configured to target the GitHub owner specified as `local.owner` (stay tuned on this...).

`provider.tf`:

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.8.0"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.30.0"
    }
  }
}

provider "github" {
  owner = local.owner
}

provider "grafana" {
  url  = "http://localhost:3000"
  auth = "admin:admin"
}
```

`data.tf` uses data sources provided by the GitHub provider to query GitHub repositories via the GitHub API and, ultimately, fetch a file tree representing the files in each repository's default branch across the targeted GitHub organization.

`data.tf`:

```hcl
data "github_repositories" "owner" {
  query = "org:${local.owner}"
}

data "github_repository" "all" {
  for_each = toset(data.github_repositories.owner.full_names)

  full_name = each.value
}

data "github_repository_branches" "all" {
  for_each = data.github_repository.all

  repository = each.value.name
}

data "github_branch" "default_branches" {
  for_each = local.github_repositories

  repository = each.value.name
  branch     = each.value.default_branch
}

data "github_tree" "all" {
  for_each = data.github_branch.default_branches

  recursive  = true
  repository = each.value.repository
  tree_sha   = each.value.sha
}
```

`locals.tf`...

* specifies [vinyldns](https://github.com/vinyldns) as the targeted GitHub organization (The use of the `vinyldns` organization is fairly arbitrary and chosen largely because its repositories feature `Dockerfile`s homed in root and non-root directories, thus simulating some of the above-listed assumptions driving the contrived example)
* exercises logic building a `local.grafana_dashboards` data structure homing the properly formatted dashboard names and corresponding Grafana folder, themselves ultimately driven by the directory location of `Dockerfile`s across [vinyldns](https://github.com/vinyldns) git repositories, and supplemented by a static list defined in an `additional_dashboards.yaml` file
* exercises logic building a `local.grafana_folders` data structure homing a deduplicated list of _just_ the Grafana folder names

`locals.tf`:

```hcl
locals {
  owner = "vinyldns"

  # filter out archived repositories and empty repositories with no branches
  github_repositories = {
    for k, v in data.github_repository.all : k => v
    if !v.archived && length(data.github_repository_branches.all[v.full_name].branches) > 0
  }

  # collect a list of objects in the format of...
  # {
  #   repo      = repository-name
  #   folder    = github-owner_repository-name
  #   dashboard = github-owner_repository-name_microservice
  # }
  # ...where `microservice` is the directory name in which a Dockerfile lives.
  # For example, the following directory structure homes 'foo' and 'bar' container images:
  # repository-name/
  #   foo/Dockerfile
  #   bar/Dockerfile
  dynamic_dashboards = distinct(flatten([
    for repo_tree in data.github_tree.all : [
      for entry in repo_tree.entries : {
        repo      = repo_tree.repository
        folder    = "${local.owner}_${replace(repo_tree.repository, ".", "")}"
        dashboard = try("${local.owner}_${replace(repo_tree.repository, ".", "")}_${split("/", entry.path)[length(split("/", entry.path)) - 2]}", "${local.owner}_${replace(repo_tree.repository, ".", "")}")
      } if endswith(entry.path, "Dockerfile")
    ]
  ]))

  # static_folders is a list of static folder configurations, as specified by additional_dashboards.yaml
  # This enables supplementing local.grafana_folders with additional, statically defined folder details.
  static_dashboards = yamldecode(file("${path.module}/additional_dashboards.yaml"))

  # grafana_dashboards is the combination of the dynamic_dashboards and static_dashboards
  grafana_dashboards = concat(local.dynamic_dashboards, local.static_dashboards)

  # grafana_folders is a list of unique folder names
  grafana_folders = distinct([
    for dashboard in local.grafana_dashboards : dashboard.folder
  ])
}
```

`additional_dashboards.yaml`:

```yaml
---
- dashboard: vinyldns_foo_bar
  folder: vinyldns_foo
- dashboard: vinyldns_baz_bim
  folder: vinyldns_baz
```

...and, ultimately, `grafana.tf` enables the creation of...

* a Grafana folder for each item in `local.grafana_folders`
* a Grafana dashboard whose name and title, respectively, corresponds to the `dashboard` attribute of each object in the `local.grafana_folders`

`grafana.tf`:

```hcl
resource "grafana_folder" "all" {
  for_each = toset(local.grafana_folders)

  title = each.value
}

resource "grafana_dashboard" "all" {
  for_each = { for dashboard in local.grafana_dashboards : dashboard.dashboard => dashboard }

  folder      = grafana_folder.all[each.value.folder].id
  config_json = jsonencode({
    title = each.value.dashboard,
    uid   = replace(lower(each.value.dashboard), "_", "-")
  })
}
```

Note that...

* In this example, the Grafana dashboard JSON is deliberately simple. However, Terraform offers options for templating more complex Grafana JSON too, either via Terraform's own [templatefile function](https://developer.hashicorp.com/terraform/language/functions/templatefile) or even via [jsonnet](https://jsonnet.org/), perhaps in concert with [grafonnet](https://grafana.github.io/grafonnet-lib/) and even a [Terraform jsonnet provider](https://registry.terraform.io/providers/alxrem/jsonnet/latest/docs), [grizzly](https://grafana.github.io/grizzly/), or other templating technologies.
* The [Grafana Terraform provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs) offers resources for managing many other aspects of Grafana too, such as teams, API keys, etc. A real-world example might manage more aspects of Grafana via Terraform, such as the dynamic creation of a unique Grafana API key for each git repository in the targeted organization, and the seeding of that key in a corresponding `GRAFANA_API_KEY` [GitHub Actions secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) in each repository. This would then enable the repositories' GitHub Actions workflows to programmatically interact with Grafana, thereby enabling further platform automation capabilities.

## Summary, Disclaimers, etc.

Again, the above-described example is somewhat contrived. In particular, because the implementation uses GitHub provider data sources to dynamically drive the dashboards and folder names, the Terraform configuration could yield different results with each `terraform apply` invocation if/when modifications to the underlying git repositories and/or their `Dockerfile`s performed in between applies. For example:

* The creation Grafana folders and dashboards pertaining to newly created git repositories and microservices would require a `terraform apply` subsquent to those git repositories' creation/modification. If necessary, this could be mitigated via automation that invokes `terraform apply` in response to relevant [GitHub organization webhook events](https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads).
* The deletion of git repositories and/or microservices could inadvertently result in the Grafana resources' destruction on subsequent `terraform apply` invocations. If undesired, this could be mitigated via the use of the [prevent_destroy](https://developer.hashicorp.com/terraform/tutorials/state/resource-lifecycle#prevent-resource-deletion) lifecyle argument, or by hardcoding such dashboards and folders in the `additional_dashboards.yaml` file. Alternatively, the use of the GitHub provider data sources could be reevaluated or evolved per real-world needs.

The above-described example is merely intended to showcase a few Terraform capabilities, and to inspire ideas. In addition to demonstrating semi-advanced logic, the configuration also teases some broader ideas for automating platform onboarding across an organization: While the example focuses largely on Grafana resources, the pattern could be applied to bootstrap other aspects of platform engineering across other providers, beyond Grafana, such as...

* PagerDuty configurations
* artifact repositories
* Vault secrets
* AWS resources, or even AWS account provisioning
* Kubernetes namespaces and other Kubernetes resources
* etc.

See [github.com/mdb/terraform-advanced-logic-demo](https://github.com/mdb/terraform-advanced-logic-demo) for the complete Terraform configuration.

---
title: "Using tfmigrate to Codify and Automate Terraform State Operations"
date: 2023-08-06T13:35:02Z
tags:
- terraform
- tfmigrate
- gitops
thumbnail: terraform3_thumb.png
teaser: "A demo illustrating the use of `tfmigrate` for automating complex Terraform state operations."
---

_An overview illustrating how [tfmigrate](https://github.com/minamijoyo/tfmigrate)
can be used to codify and automate complex Terraform state operations. The
corresponding reference example code can be viewed at [github.com/mdb/tfmigrate](https://github.com/mdb/tfmigrate-demo)._

## Problem

The `terraform` CLI exposes a suite of [state commands](https://developer.hashicorp.com/terraform/cli/commands/state)
for advanced state management. However, these commands often require that engineers
employ error-prone, manual, and ad hoc invocations of the `terraform` CLI
out-of-band of CI/CD and code review.

How can we automate the migration of a Terraform-managed resource from
one root module project configuration to a different root module project
configuration, each using different S3 [remote states](https://developer.hashicorp.com/terraform/language/state/remote)?

And what if each root module project uses a different version of Terraform?

How can the solution utilize a GitOps workflow in which state migration operations
are codified, and subject to code review, continuous integration quality checks,
and continuous delivery automation, similar to other Terraform operations, or
even [database migrations](https://edgeguides.rubyonrails.org/active_record_migrations.html)?

## Solution

Use [tfmigrate](https://github.com/minamijoyo/tfmigrate) in concert with [tfenv](https://github.com/tfutils/tfenv).

## Demo

[mdb/tfmigrate-demo](https://github.com/mdb/tfmigrate-demo) offers a demo, and
utilizes Github Actions as the underlying CI/CD platform.

### Overview

Within [mdb/tfmigrate-demo](https://github.com/mdb/tfmigrate-demo)...

* `bootstrap` is a minimal Terraform project that creates a [localstack](https://localstack.cloud/)
  `tfmigrate-demo` S3 bucket for use hosting `project-one` and `project-two`'s
   Terraform remote states
* `project-one` is a minimal Terraform 0.13.7 project that creates `foo.txt` and
  `bar.txt` files and uses `s3://tfmigrate-demo/project-one/terraform.tfstate` as
  its remote state backend.
* `project-two` is a minimal Terraform 1.4.6 project that creates a `baz.txt` file
  and uses `s3://tfmigrate-demo/project-two/terraform.tfstate`
  as its remote state backend.
* `project-one` and `project-two` each feature a `.terraform-version` file. This
  ensures [tfenv](https://github.com/tfutils/tfenv) selects the proper Terraform
  for use in each project.
* `migration.hcl` is a [tfmigrate](https://github.com/minamijoyo/tfmigrate) migration that orchestrates the migration
  of `local_file.bar` from management in `project-one` to management in `project-two`.
  `tfmigrate` enables teams to codify migrations as HCL, subjecting the
  migrations to code review and CI/CD, alongside terraform HCL configurations.
* `.tfmigrate.hcl` is a `tfmigrate` configuration file specifying that
  `tfmigrate`'s migration history be persisted to
  `s3://tfmigrate-demo/tfmigrate/history.json`.

See [PR 2](https://github.com/mdb/tfmigrate-demo/pull/2) for an example GitHub
Actions workflow that fails its `tfmigrate plan` step. See [PR 3](https://github.com/mdb/tfmigrate-demo/pull/3) for an example
GitHub Actions workflow that successfully performs a `tfmigrate apply`.

See [.github/workflows/pr.yaml](https://github.com/mdb/tfmigrate-demo/blob/main/.github/workflows/pr.yaml)
for the GitHub Actions workflow configuration.

### Self-guided tutorial

In alternative to the [GitHub Actions-based demo](https://github.com/mdb/tfmigrate-demo/actions),
the following steps offer a self-guided tutorial. These steps assumes Docker is
running, and that [tfmigrate](https://github.com/minamijoyo/tfmigrate) and [tfenv](https://github.com/tfutils/tfenv) are both installed.

1. Clone `tfmigrate-demo`:

    ```
    git clone https://github.com/mdb/tfmigrate-demo.git \
      && cd tfmigrate-demo
    ```

1. Install the Terraform versions used by `project-one` and `project-two` via `tfenv`:

    ```
    TFENV_ARCH=amd64 tfenv install v$(cat project-one/.terraform-version) \
      && tfenv install v$(cat project-two/.terraform-version)
    ```

1. Start a `localstack`-based mock AWS environment:

    ```
    docker-compose up \
      --detach \
      --build
    ```
1. Create a local `localstack` `tfmigrate-demo` AWS S3 bucket for homing
   `project-one`'s and `project-two`'s S3 remote state:

    ```
    cd bootstrap \
      && terraform init \
      && terraform plan \
      && terraform apply \
        -auto-approve
    ```

1. Create an initial `project-one` Terraform configuration. This creates local
   `foo.txt` (`local_file.foo`) and `bar.txt` (`local_file.bar`) files:

    ```
    cd project-one \
      && terraform init \
      && terraform plan \
      && terraform apply \
        -auto-approve
    ```

1. Create an initial `project-two` Terraform configuration. This creates a local
   `baz.txt` (`local_file.baz`) file:

    ```
    cd project-two \
      && terraform init \
      && terraform plan \
      && terraform apply \
        -auto-approve
    ```

1. Run use [tfmigrate](https://github.com/minamijoyo/tfmigrate) to list any outstanding migrations:

    ```
    tfmigrate list --status=unapplied
    2023/08/15 19:30:44 [INFO] AWS Auth provider used: "StaticProvider"
    migration.hcl
    ```

    Based on `tfmigrate list`'s output, the `migration.hcl` file contains an
    unapplied migration that seeks to move `local_file.bar` from `project-one` to `project-two`:

    ```hcl
    migration "multi_state" "mv_local_file_bar" {
      from_dir = "project-one"
      to_dir   = "project-two"

      actions = [
        "mv local_file.bar local_file.bar",
      ]
    }
    ```

1. Next, use [tfmigrate](https://github.com/minamijoyo/tfmigrate) to `plan` the
   migration of `local_file.bar` from `project-one`'s Terraform state to
   `project-two`'s Terraform state using the migration instructions codified in
   `migration.hcl`, which move `local_file.bar` from `project-one` to
   `project-two`.

    Note that `tfmigrate plan` will "dry run" the migration using a local, dummy
    copy of each project's remote state and will performs a `terraform plan`,
    erroring if the migration results in any unexpected plan changes.

    Also note that `tfmigrate` automatically uses the correct `terraform` CLI version
    required by each project, as each project's `.terraform-version` file triggers
    `tfenv` to ensure the correct version is used.

    Initially, observe that `tfmigrate plan migration.hcl` fails, as `local_file.bar`'s
    HCL recource declaration has not moved from `project-one` to `project-two`; it
    still lives in `project-one/main.tf`:

    ```
    tfmigrate plan
    2023/08/15 19:40:23 [INFO] AWS Auth provider used: "StaticProvider"
    2023/08/15 19:40:23 [INFO] [runner] unapplied migration files: [migration.hcl]
    2023/08/15 19:40:23 [INFO] [runner] load migration file: migration.hcl
    2023/08/15 19:40:23 [INFO] [migrator] multi start state migrator plan
    2023/08/15 19:40:24 [INFO] [migrator@project-one] terraform version: 0.13.7
    2023/08/15 19:40:24 [INFO] [migrator@project-one] initialize work dir
    2023/08/15 19:40:24 [INFO] [migrator@project-one] get the current remote state
    2023/08/15 19:40:24 [INFO] [migrator@project-one] override backend to local
    2023/08/15 19:40:24 [INFO] [executor@project-one] create an override file
    2023/08/15 19:40:24 [INFO] [migrator@project-one] creating local workspace folder in: project-one/terraform.tfstate.d/default
    2023/08/15 19:40:24 [INFO] [executor@project-one] switch backend to local
    2023/08/15 19:40:25 [INFO] [migrator@project-two] terraform version: 1.4.6
    2023/08/15 19:40:25 [INFO] [migrator@project-two] initialize work dir
    2023/08/15 19:40:26 [INFO] [migrator@project-two] get the current remote state
    2023/08/15 19:40:26 [INFO] [migrator@project-two] override backend to local
    2023/08/15 19:40:26 [INFO] [executor@project-two] create an override file
    2023/08/15 19:40:26 [INFO] [migrator@project-two] creating local workspace folder in: project-two/terraform.tfstate.d/default
    2023/08/15 19:40:26 [INFO] [executor@project-two] switch backend to local
    2023/08/15 19:40:27 [INFO] [migrator] compute new states (project-one => project-two)
    2023/08/15 19:40:27 [INFO] [migrator@project-one] check diffs
    2023/08/15 19:40:28 [ERROR] [migrator@project-one] unexpected diffs
    2023/08/15 19:40:28 [INFO] [executor@project-two] remove the override file
    2023/08/15 19:40:28 [INFO] [executor@project-two] remove the workspace state folder
    2023/08/15 19:40:28 [INFO] [executor@project-two] switch back to remote
    2023/08/15 19:40:28 [INFO] [executor@project-one] remove the override file
    2023/08/15 19:40:28 [INFO] [executor@project-one] remove the workspace state folder
    2023/08/15 19:40:28 [INFO] [executor@project-one] switch back to remote
    terraform plan command returns unexpected diffs in project-one from_dir: failed to run command (exited 2): terraform plan -state=/var/folders/46/sz1dzp417x7fk46kb3jv8cn00000gp/T/tmp3859825156 -out=/var/folders/46/sz1dzp417x7fk46kb3jv8cn00000gp/T/tfplan265876470 -input=false -no-color -
    detailed-exitcode
    stdout:
    Refreshing Terraform state in-memory prior to plan...
    The refreshed state will be used to calculate this plan, but will not be
    persisted to local or remote state storage.

    local_file.foo: Refreshing state... [id=94dd9e08c129c785f7f256e82fbe0a30e6d1ae40]

    ------------------------------------------------------------------------

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # local_file.bar will be created
      + resource "local_file" "bar" {
          + content              = "Hi"
          + content_base64sha256 = (known after apply)
          + content_base64sha512 = (known after apply)
          + content_md5          = (known after apply)
          + content_sha1         = (known after apply)
          + content_sha256       = (known after apply)
          + content_sha512       = (known after apply)
          + directory_permission = "0777"
          + file_permission      = "0777"
          + filename             = "./../bar.txt"
          + id                   = (known after apply)
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    ------------------------------------------------------------------------

    This plan was saved to: /var/folders/46/sz1dzp417x7fk46kb3jv8cn00000gp/T/tfplan265876470

    To perform exactly these actions, run the following command to apply:
        terraform apply "/var/folders/46/sz1dzp417x7fk46kb3jv8cn00000gp/T/tfplan265876470"


    stderr:
    ```

1. Next, remove the `local_file.bar` declaration from `project-one/main.tf` and add
   it to `project-two/main.tf`, such that each project configuration reflects the
   desired migration end state:

   `project-one/main.tf` should appear as:

   ```hcl
   resource "local_file" "foo" {
    content  = "Hi"
    filename = "${path.module}/../foo.txt"
   }
   ```

   `project-two/main.tf` should now appear as:

    ```hcl
    resource "local_file" "baz" {
      content  = "Hi"
      filename = "${path.module}/../baz.txt"
    }

    resource "local_file" "bar" {
      content  = "Hi"
      filename = "${path.module}/../bar.txt"
    }
    ```

1. Re-run `tfmigrate plan migration.hcl`; now it's successful:

   ```

    ```

1. Finally, to perform the migration, `apply` the `migration.hcl`:

    ```
    tfmigrate plan
    2023/08/15 19:41:16 [info] aws auth provider used: "staticprovider"
    2023/08/15 19:41:16 [info] [runner] unapplied migration files: [migration.hcl]
    2023/08/15 19:41:16 [info] [runner] load migration file: migration.hcl
    2023/08/15 19:41:16 [info] [migrator] multi start state migrator plan
    2023/08/15 19:41:17 [info] [migrator@project-one] terraform version: 0.13.7
    2023/08/15 19:41:17 [info] [migrator@project-one] initialize work dir
    2023/08/15 19:41:17 [info] [migrator@project-one] get the current remote state
    2023/08/15 19:41:17 [info] [migrator@project-one] override backend to local
    2023/08/15 19:41:17 [info] [executor@project-one] create an override file
    2023/08/15 19:41:17 [info] [migrator@project-one] creating local workspace folder in: project-one/terraform.tfstate.d/default
    2023/08/15 19:41:17 [info] [executor@project-one] switch backend to local
    2023/08/15 19:41:18 [info] [migrator@project-two] terraform version: 1.4.6
    2023/08/15 19:41:18 [info] [migrator@project-two] initialize work dir
    2023/08/15 19:41:19 [info] [migrator@project-two] get the current remote state
    2023/08/15 19:41:19 [info] [migrator@project-two] override backend to local
    2023/08/15 19:41:19 [info] [executor@project-two] create an override file
    2023/08/15 19:41:19 [info] [migrator@project-two] creating local workspace folder in: project-two/terraform.tfstate.d/default
    2023/08/15 19:41:19 [info] [executor@project-two] switch backend to local
    2023/08/15 19:41:19 [info] [migrator] compute new states (project-one => project-two)
    2023/08/15 19:41:20 [info] [migrator@project-one] check diffs
    2023/08/15 19:41:21 [info] [migrator@project-two] check diffs
    2023/08/15 19:41:21 [info] [executor@project-two] remove the override file
    2023/08/15 19:41:21 [info] [executor@project-two] remove the workspace state folder
    2023/08/15 19:41:21 [info] [executor@project-two] switch back to remote
    2023/08/15 19:41:22 [info] [executor@project-one] remove the override file
    2023/08/15 19:41:22 [info] [executor@project-one] remove the workspace state folder
    2023/08/15 19:41:22 [info] [executor@project-one] switch back to remote
    2023/08/15 19:41:22 [info] [migrator] multi state migrator plan success!
    ```

1. To verify `project-one` and `project-two` have no outstanding post-migration Terraform plan diffs:

    ```
    cd project-one \
      && terraform init \
      && terraform plan \
      && terraform apply \
        -auto-approve

    ...

    No changes. Infrastructure is up-to-date.
    ```

    ```
    cd project-two \
      && terraform init \
      && terraform plan \
      && terraform apply \
        -auto-approve
    ...

    No changes. Infrastructure is up-to-date.
    ```

1. Check `tfmigrate `migration history

    `.tfmigrate.hcl` configures `tfmigrate`'s [history](https://github.com/minamijoyo/tfmigrate#history-block),
    which records migration history and status as a JSON document.

    To view the history JSON:

    ```
    curl http://localhost.localstack.cloud:4566/tfmigrate-demo/tfmigrate/history.json
    {
        "version": 1,
        "records": {
            "migration.hcl": {
                "type": "multi_state",
                "name": "mv_local_file_bar",
                "applied_at": "2023-08-09T10:22:59.897417-04:00"
            }
        }
    }
    ```

    `tfmigrate list` can also be used to view all migrations:

    ```
    tfmigrate list
    migration.hcl
    ```

    Alternatively, `tfmigrate list --status=unapplied` reports any outstanding, unapplied migrations:

    ```
    tfmigrate list --status=unapplied
    ```

## A real world GitOps workflow

The steps described above are a bit contrived, in large part because `tfmigrate-demo`
uses ephemeral local Terraform projects whose resources and state aren't persistant.

A real world GitOps-esque team workflow against an existing project might look more like...

1. Open a PR containing the desired `tfmigrate` migration HCL and desired Terraform
   configuration changes.
2. CI detects the presence of a `tfmigrate` migration HCL and verifies the
   changes via `tfmigrate plan`.
3. Following successful CI and code review approval, the PR is merged.
4. CI/CD detects the presence of the new `tfmigrate` migration HCL  and performs
   `tfmigrate plan` and `tfmigrate apply` to perform the migration, similar to
   what's done via `terraform plan` and `terraform apply` for other Terraform
   changes.

While `tfmigrate-demo` largely focuses on inter-state move operations,
`tfmigrate` supports [other operations](https://github.com/minamijoyo/tfmigrate#migration-file) too,
including `state rm` and `state import`.

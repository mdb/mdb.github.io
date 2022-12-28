---
title: Extending the gh CLI with Go
date: 2022-12-28
tags:
- go
- platform engineering
- github
- cli
thumbnail: red_brick_thumb.png
teaser: Some introductory tips on building gh CLI extensions in Go.
---

_GitHub's [gh CLI](https://cli.github.com/) can be enhanced via custom extensions. The following offers an introduction, as well as some notes and tips for doing so in Go._

1. [What?](#what?)
1. [Extensions](#extensions)
1. [How do gh extensions work?](#how-do-gh-extensions-work)
1. [Implementation tips, suggestions, etc.](#implementation-tips-suggestions-etc)
1. [Bonus experimental idea: bootstrapping developer experience and platform engineering](#bonus-experimental-idea-bootstrapping-developer-experience-and-platform-engineering)
1. [Further reading](#further-reading)

## What?

Out of the box, the [gh CLI](https://cli.github.com/) supports a collection of commands for interacting with GitHub features like repositories, releases, pull requests, and more. For example, to view a repository's open pull requests, use `gh pr ls`:

![demo](/images/blog/gh_pr_demo.gif)

`gh` can be installed via common package managers (`brew install gh` on Mac OS). It's also preinstalled on all [GitHub-hosted Actions runners](https://docs.github.com/en/actions/using-workflows/using-github-cli-in-workflows) and available for use in GitHub Actions CI/CD pipelines, as demonstrated by [mdb/ensure-unpublished-release-action's release pipeline](https://github.com/mdb/ensure-unpublished-release-action/blob/main/.github/workflows/test.yml#L68), which invokes `gh release create` to publish [GitHub releases](https://github.com/mdb/ensure-unpublished-release-action/releases).

## Extensions

Beyond its built-in features, `gh` can be extended to support custom commands. I recently created the [gh-dispatch](https://github.com/mdb/gh-dispatch) extension for triggering [repository_dispatch](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event) and/or [workflow_dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch) events and watching the resulting [GitHub Actions workflow run](https://github.com/mdb/gh-dispatch/actions/runs/3509863404). Once installed, the extension provides a `gh dispatch` command:

![demo](/images/blog/gh_dispatch_demo.gif)

`gh extension install` installs extensions from their GitHub repositories. To install `gh-dispatch`:

```
gh extension install mdb/gh-dispatch
```

...and to view all installed extensions, use `gh extension list`:

```
gh actions-importer  github/gh-actions-importer    v1.0.1
gh actions-status    rsese/gh-actions-status       v1.0.0
gh dash              dlvhdr/gh-dash                v3.4.1
gh dispatch          mdb/gh-dispatch               0.0.1
gh markdown-preview  yusukebe/gh-markdown-preview  198c536b
gh metrics           hectcastro/gh-metrics         v2.1.0
```

A few extensions of note include...

* [gh-dash](https://github.com/dlvhdr/gh-dash) - a Terminal dashboard for GitHub issues and pull requests
* [gh-install](https://github.com/redraw/gh-install) - install GitHub release binaries
* [gh-changelog](https://github.com/chelnak/gh-changelog) - create [keep a changelog](https://keepachangelog.com/en/1.0.0/)-style changelogs

To see other community-maintained `gh` extensions, [browse GitHub repositories tagged with the "gh-extension" topic](https://github.com/topics/gh-extension).

## How do gh extensions work?

Under the hood, `gh` CLI extensions are `gh-`-prefixed executables located at a standard path (sidebar: this is similar to how [kubectl plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) work too). For example, on Mac OS, the executables live in `~/.local/share/gh/extensions`:

```
ls ~/.local/share/gh/extensions
gh-actions-importer gh-dispatch gh-metrics
gh-actions-status   gh-dash     gh-markdown-preview
```

With this in mind, a rudimentary extension might be a simple `bash` script named and located accordingly:

```
cat ~/.local/share/gh/extensions/gh-hello/gh-hello
#!/bin/bash

echo "hello"
```

...and thereby executable as a `gh` subcommand:

```
gh hello
hello
```

So, returning to the [gh-dispatch](https://github.com/mdb/gh-dispatch) example...

`gh extension install mdb/gh-dispatch` fetches the `gh-dispatch` extension from GitHub and, at least in the case of Mac OS, installs it to the `~/.local/share/extensions/gh-dispatch` path. Because `gh-dispatch`'s own [build process](https://github.com/mdb/gh-dispatch/actions/workflows/cicd.yaml) precompiles the extension for various OS/architecture combos and publishes the resulting binaries to a [GitHub release](https://github.com/mdb/gh-dispatch/releases/), `gh extension install` knows to download the correct binary associated with the targeted release version (by default, it fetches the latest release, though specific versions can be targeted with a `--pin` option).

(Arguably, all this becomes especially compelling when considering the growing ubiquity of GitHub, the widespread popularity of the `gh` CLI, and that `gh extension install` requires no additional package managers, local runtimes, or developer environment setup, at least in the case of precompiled extensions like [gh-dispatch](https://github.com/mdb/gh-dispatch). So, with this in mind, perhaps a custom `gh` extension could be leveraged as a sensible entrypoint when bootsrapping higher level developer experiences for an organization -- think platform onboarding, environment setup, repository generation, secrets management, build utilities, etc. But, more on all that later).

## Implementation tips, suggestions, etc.

While a `gh` extension can be authored in any language, Go is an especially good fit for a few reasons:

1. The `gh` CLI itself is authored in Go.

    Because `gh` itself is written in Go using the [Cobra framework](https://cobra.dev/), its source code offers lotsa helpful examples and patterns. For example, the `gh pr list` [implementation](https://github.com/cli/cli/blob/v2.21.1/pkg/cmd/pr/list/list.go) reveals how `gh` subcommands are declared as a [&cobra.Command](https://pkg.go.dev/github.com/spf13/cobra#Command).

    Furthermore, the packages homed in https://github.com/cli/cli/ can also be imported by extension source code, which enables helpful reuse patterns. As an example, `gh-dispatch` leverages upstream https://github.com/cli/cli/ packages, particularly when [rendering output](https://github.com/mdb/gh-dispatch/blob/main/internal/dispatch/renderutils.go). A few other packages of note include...

    * [github.com/cli/cli/v2/api](https://github.com/cli/cli/tree/v2.21.1/api) - a GitHub API client.
    * [github.com/cli/cli/v2/pkg/httpmock](https://github.com/cli/cli/tree/v2.21.1/pkg/httpmock) - utilities for mocking HTTP transactions during automated tests (see [gh-dispatch's own tests](https://github.com/mdb/gh-dispatch/blob/0.1.3/internal/dispatch/repository_test.go) for example usage).
    * [github.com/cli/cli/v2/pkg/iostreams](https://github.com/cli/cli/tree/v2.21.1/pkg/iostreams) - utilities for working with IO and rendering CLI extension output.

    Disclaimer: I'm not actually sure the `gh` maintainers intend for these packages to be used outside the CLI codebase, but it can be done.

2. [github.com/cli/go-gh](https://github.com/cli/go-gh) can be used by Go-based extensions.

    In addition to the https://github.com/cli/cli/ packages, `github.com/cli/go-gh` is also available to Go-based extension developers. According to `go-gh`'s own `README:`

    > `go-gh` is a collection of Go modules to make authoring [GitHub CLI extensions](https://docs.github.com/en/github-cli/github-cli/creating-github-cli-extensions) easier.

    For example, `gh-dispatch` uses [github.com/cli/go-gh/pkg/auth](https://github.com/cli/go-gh/tree/v1.0.0/pkg/auth) and [github.com/cli/go-gh/pkg/config](https://github.com/cli/go-gh/tree/v1.0.0/pkg/config) to ensure the extension authenticates users to GitHub via the same patterns used by the core `gh` CLI.

3. Go programs can be easily precompiled across OS/architecture combos.

    By precompiling a CLI extension, users can install and run the extension without additional run time dependencies (i.e. bash, Ruby, Python, etc.) beyond the `gh` CLI itself, nor is it necessary to provide users any per-OS/per-architecture installation instructions; `gh extension install <OWNER>/<REPO>` simply downloads the appropriate binary from the `<OWNER>/<REPO>` GitHub releases (For example, note the precompiled binaries associated with each of [gh-dispatch's GitHub releases](https://github.com/mdb/gh-dispatch/releases)).

    Also helpful: [gh-extension-precompile](https://github.com/cli/gh-extension-precompile) is a reusable GitHub Action for automating the publication of such binaries to GitHub releases, saving Go-based extension authors from writing their own CI/CD automation. However, if you'd prefer to write your own release automation -- or to use [goreleaser](https://goreleaser.com/) directly, as [gh-dispatch's release process does](https://github.com/mdb/gh-dispatch/blob/main/.github/workflows/cicd.yaml) -- that's not too hard, either (just make sure the precompiled binaries are named correctly; `gh extension install` assumes a naming convention. When in doubt, emulate a known working example, such as [gh-dispatch](https://github.com/mdb/gh-dispatch)).

## Bonus experimental idea: bootstrapping developer experience and platform engineering

While `gh` extensions are useful in and of themselves (I use [gh-dash](https://github.com/dlvhdr/gh-dash) every day!), the ecosystem teases some broader possibilities: could a `gh` extension be a cornerstone of an organization's developer platform experience?

In my experience, it's common for engineering leadership to fantasize about a cohesive internal developer platform, often facilitated via a purpose-built CLI, web portal, and/or API, and enabling developer efficiency via stuff like...

* a standard interface to centralized automation, such as GitHub Actions workflows
* automated software project and repository scaffolding
* the generation and maintenance of standard, templated CI/CD pipelines
* the maintenance of source code repository best practices, such as [standard required status checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks) and [required PR code review approvals](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/approving-a-pull-request-with-required-reviews)
* per-team public cloud provider account provisioning and infrastructure setup
* the management of role-based access control, secrets such as API credentials, and similar security-sensitive safeguards
* a common interface to otherwise disparate tools, such as documentation, project management, dashboards, etc.
* a general purpose mechanism for self-service and the discovery of ever-evolving internal capabilities

However, depending on context (org size, priorities, etc.), building a developer platform involves labor and complexity that may jeopardize more business-critical efforts, especially when doing so invests in proprietary solutions to common needs. To varying degrees, open tools like [Backstage](https://backstage.io) and various [Internal Developer Platforms](https://internaldeveloperplatform.org/) aspire to help. Zooming out, even Kubernetes itself -- despite its complexity -- aspires to be an open, common, standard-ish platform. Technologies like [Kubevela](https://github.com/kubevela/kubevela) further enhance the Kubernetes platform experience. These are great tools. But, perhaps building on the ubiquity of the existing GitHub ecosystem via a custom `gh` extension might be a relatively low-effort, low-risk compliment to your organization's developer experience as well? Or maybe a sensible entrypoint before tools beyond GitHub are implicated?

(In my experience, an organization-specific `gh` extension becomes especially attractive when it serves as an interface to other heavily-used GitHub features: GitHub Actions workflows, GitHub pages-hosted JSON endpoints, GitHub secrets, GitHub environments, etc.).

A big disclaimer, though: all this `gh`-extension-facilitated developer experience talk is bit experimental and intended only as food for thought. Context and nuance matters, do your own thinkin'/assessin', your mileage may vary, maybe [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it), etc.

## Further reading

* [gh documentation](https://cli.github.com/manual/gh_extension)
* [Creating GitHub CLI Extensions](https://docs.github.com/en/github-cli/github-cli/creating-github-cli-extensions)
* [Community-maintained extensions](https://github.com/topics/gh-extension)

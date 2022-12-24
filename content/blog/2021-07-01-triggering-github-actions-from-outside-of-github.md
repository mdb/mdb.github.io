---
title: Triggering GitHub Actions From Outside of GitHub
date: 2021-07-01
tags:
- github
- CI/CD
thumbnail: computer_thumb.jpg
teaser: An introduction to using custom repository dispatch events to trigger GitHub Actions.
---

_An introduction to using custom repository dispatch events to trigger GitHub Actions from outside of GitHub._

Often, [GitHub Actions](https://docs.github.com/en/actions) are configured to trigger in response to common [GitHub events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows), such as pushing a git commit, opening a pull request, or creating a git tag. But how can GitHub Actions workflows be triggered from events outside of GitHub? GitHub's [`repository_dispatch`](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#repository_dispatch) event offers a solution.

## A basic example

First, create a `.github/workflows/repo_dispatch_example.yml` file (the name is arbitrary, though its location and `.yml` extension do matter):

```yml
name: Hello

on:
  repository_dispatch

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Say-Hello
        run: echo "Hello!"
```

After committing and pushing the `.github/workflows/repo_dispatch_example.yml` file, the `Hello` workflow's `greet` job can be triggered via a GitHub API request (note that this assumes a `GITHUB_TOKEN` environment variable whose value is an authorized [GitHub personal access token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)):

```sh
curl \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --request "POST" \
  --data '{"event_type": "hello"}' \
  "https://api.github.com/repos/<OWNER>/<REPOSITORY>/dispatches"
```

As a result, the `Hello` workflow is triggered and its `Say-Hello` step prints `Hello!`.

## A slightly more advanced example

The above `Hello` workflow implementation responds to any properly issued repository dispatch API request. However, GitHub Actions also supports the ability to configure workflows that only respond to specific events, as well as the ability to pass arbitrary data to the workflow via the repository dispatch API request payload. The following variation of `.github/workflows/repo_dispatch_example.yml` is _only_ triggered by repository dispatch API requests whose `event_type` is `hello`, and also uses a `name` from the request payload's `client_payload` field:

```yml
name: Hello

on:
  repository_dispatch:
    type: ["hello"]

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Say-Hello
        run: echo "Hello, ${{ github.event.client_payload.name }}!"
```

The new `Hello` workflow can be triggered like so:

```sh
curl \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --request "POST" \
  --data '{"event_type": "hello", "client_payload": {"name":"Mike"}}' \
  "https://api.github.com/repos/<OWNER>/<REPOSITORY>/dispatches"
```

This results in a `Say-Hello` step that prints `Hello, Mike!`, as seen in [this example](https://github.com/mdb/mikeball.info/runs/2968213309?check_suite_focus=true).

However, requests whose payloads specify an `event_type` other than `hello`, such as the following, no longer trigger the `Hello` workflow:

```sh
curl \
  --header "Accept: application/vnd.github.v3+json" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --request "POST" \
  --data '{"event_type": "goodbye"}' \
  "https://api.github.com/repos/<OWNER>/<REPOSITORY>/dispatches"
```

## Gotchas

Based on experimentation, it _seems_ requests to `repos/<OWNER>/<REPOSITORY>/dispatches` only trigger workflows whose `.github/workflows/*.yml` configuration exists in the repository's default branch.

## 2022 update

I created the [gh-dispatch](https://github.com/mdb/gh-dispatch/) `gh` CLI extension for triggering [repository_dispatch](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event) and/or
[workflow_dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch) events and watching the resulting GitHub Actions
workflow run. The tool offers a CLI for performing `POST /repos/<OWNER>/<REPOSITORY>/dispatches` requests like those described above, and also enables users to watch the resulting GitHub Actions workflow run directly from the terminal:

![demo](/images/blog/gh_dispatch_demo.gif)


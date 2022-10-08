---
title: Querying GitHub Release Data With gh and jq
date: 2022-10-02
tags:
- gh
- jq
- github
thumbnail: party_camo_thumb.png
teaser: Fetch the latest patch release of each of the latest 5 minor versions of Grafana
---

A demo of semi-advanced `gh` CLI and `jq` querying techniques.

## Problem

You'd like to list the latest patch release associated with each of the latest 5 minor versions of Grafana represented as a JSON array.

For example:

```json
["9.1.6","9.0.9","8.5.13","8.4.11","8.3.11"]
```

## Solution

Leverage that...

1. Grafana releases are published as [GitHub releases](https://github.com/grafana/grafana/releases)
1. The [gh](https://cli.github.com/) CLI supports an `api` command, enabling users to query GitHub API endpoints
1. The GitHub API supports a [list releases](https://docs.github.com/en/rest/releases/releases#list-releases) endpoint
1. `gh api` supports a `--jq` flag, enabling the ability to invoke `jq` queries against GitHub API responses

For example:

```shell
gh api 'repos/grafana/grafana/releases?per_page=100' \
  --jq '
    [
      .[]
      | select(.prerelease or .draft | not)
      | .tag_name[1:100]
      | select(contains("-") | not)
    ]
    | map({
      major: (split(".")[0]),
      minor: (split(".")[1]),
      patch: (split(".")[2])
    })
    | group_by(.major, .minor)
    | reverse
    | map(.[0] | join("."))[:5]
    '
```

Example result (this is subject to change as additional Grafana releases are published):

```json
["9.1.6","9.0.9","8.5.13","8.4.11","8.3.11"]
```

A few implementation notes:

* `?per_page=100` ensures the API response contains the last 100 releases (if the latest path release associated with each of the latest 5 minor versions of Grafana are not all amongst the last 100 releases, this solution may not work and paginating through multiple pages' of API responses might be necessary)
* The query filters out releases denoted as prereleases and drafts, as well as any whose name contains a `-` (Example: `9.2.0-beta1`), the presence of which also likely signifies an "unofficial" release
* The example focuses on Grafana, though is applicable to any project that publishes [semantically versioned](https://semver.org/) GitHub releases

## Footnotes

I originally cooked up this solution in an attempt to address [terraform-provider-grafana issue 411](https://github.com/grafana/terraform-provider-grafana/issues/411) via [pull request 572](https://github.com/grafana/terraform-provider-grafana/pull/572).

Understandably, though, the `terraform-provider-grafana` maintainers ultimately decided against addressing [issue 411](https://github.com/grafana/terraform-provider-grafana/issues/411#issuecomment-1261618932) given the complexity required in doing so. Plus, it's possible my solution is flawed. A better, more elegant technique may exist.

Nonetheless, perhaps others will benefit from its documentation. See a better solution? [Submit a PR](https://github.com/mdb/mdb.github.io/pulls).

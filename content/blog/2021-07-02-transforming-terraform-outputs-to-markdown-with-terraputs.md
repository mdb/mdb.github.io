---
title: Transforming Terraform Output Values to Markdown with Terraputs
date: 2021-07-02
tags:
- terraform
- CI/CD
- automation
thumbnail: hope_fingers_thumb.jpg
teaser: An introduction to using terraputs.
---

_An introduction to using a tool I wrote, [`terraputs`](https://github.com/mdb/terraputs), to transform Terraform configuration [output values](https://www.terraform.io/docs/language/values/outputs.html) to markdown. I owe a hat tip to my colleagues [Justin LaRose](https://github.com/justinlarose) and [Travis Truman](https://github.com/trumant) for giving me the idea to create `terraputs`._

## Problem

You'd like to publish your [Terraform](https://terraform.io) configuration's up-to-date [output values](https://www.terraform.io/docs/language/values/outputs.html) in a human-friendly, easy-to-read, accessible format. Perhaps you'd like to publish their current values to your project's `README.md`, a wiki, or some other form of documentation.

## Solution

[terraputs](https://github.com/mdb/terraputs) is a minimal CLI tool I created to print Terraform output values as [markdown](https://www.markdownguide.org).

## Usage

`terraputs` accepts a `-state` flag, the value of which should be a Terraform configuration's state JSON, as represented by `terraform show -json`. For example:

```sh
terraputs \
  -state $(terraform show -json)
```

As a result, `terraputs` reads the Terraform configuration's state, parses the outputs' names, values, and types, and prints a markdown representation. For example:

```txt
# Terraform Outputs

Terraform state outputs.

| Output | Value | Type
| --- | --- | --- |
| a_basic_map | map[foo:bar number:42] | map[string]interface {}
| a_list | [foo bar] | []interface {}
| a_nested_map | map[baz:map[bar:baz id:123] foo:bar number:42] | map[string]interface {}
| a_sensitive_value | sensitive; redacted | string
| a_string | foo | string
```

`terraputs` also accepts an optional `-heading` flag for specifying the heading value. For example:

```sh
terraputs \
  -state $(terraform show -json)
  -heading "Terraform outputs for `$(terraform workspace show)`"
```

...which could result in a custom heading clarifying context, such as the output values' environment or [workspace](https://www.terraform.io/docs/language/state/workspaces.html):

```txt
# Terraform outputs for `production-aws-us-east-1`
```

## Demo

<script id="asciicast-423523" src="https://asciinema.org/a/423523.js" async></script>

The demo shows...

1. applying a [Terraform](https://terraform.io) configuration with output values of various types
1. using [terraputs](https://github.com/mdb/terraputs) to save the Terraform configuration’s outputs as an `OUTPUTS.md` markdown file, in effect surfacing human-friendly documentation of the up-to-date outputs values that can be published to a git repo, wiki, and/or project documentation.
1. using [glow](https://github.com/charmbracelet/glow) to render the `OUTPUTS.md` file, providing viewers a sense of its rendered formatting

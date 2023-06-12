---
title: "Using the gh-dash gh CLI Extension to Manage GitHub Notifications"
date: 2023-05-31T13:35:02Z
tags:
- gh
- cli
- github
thumbnail: github_bordered_thumb.png
teaser: How I use the gh-dash gh CLI extension to manage GitHub notifications.
---

_Written towards the goal of sharing my own practice with new team members, the
following offers an overview of how I use the `gh-dash` CLI extension to manage
GitHub notifications and pull request discussion_.

## Problem

At scale, staying abreast of GitHub code review requests, GitHub issues of note,
and related discussions is challenging. The challenges are further compounded
when working across multiple GitHub organizations on both open and closed source
projects, and especially when working as a member of multiple GitHub teams
within one or more organizations.

For example, some of the challenges may include:

* differentiating between extra curricular open source projects and employer
  projects
* differentiating between work associated with different teams within the same
  project
* differentiating between open, closed, merged, and draft PRs
* giving priority to employer projects during formal working hours
* staying abreast of ongoing code review conversation on my own open pull
  requests
* staying abreast of ongoing code review conversation on my own _closed_ pull
  requests, if/when comments appear after the PRs have been merged
* staying abreast of instances where my or my team's code review is requested
* staying abreast of ongoing conversation following my code review
* staying abreast of instances where I'm mentioned in conversation, but when my
  review has not been formally requested
* staying abreast of relevant ongoing conversation on my others' _closed_ PRs,
  after the PRs have been merged
* monitoring discussion of interest on both open and closed PRs where my
  review has not been explicitly requested and where I've not been explicitly mentioned
* being able to further filter and/or create arbitrary categorizations of the
  above-cited flavors of discussions

(Much of the challenges above specifically mention pull requests, but also apply
to GitHub issues. For example, perhaps your employer uses Jira rather than GitHub
issues, but your extra curricular open source work is tracked via GitHub issues.)

## Solution

Different techniques and tooling exists for managing all this, though `gh-dash`
has been my favorite for a few years.

[gh-dash](https://github.com/dlvhdr/gh-dash) is a community-maintained [extension to the gh CLI](/blog/extending-the-gh-cli-with-go/).
It offers a customizeable terminal dashboard for filtering, sorting, and browsing
GitHub pull requests, issues, and surrounding discussion and code reviews.

Installation:

After [installing the gh CLI](https://cli.github.com/manual/installation),
install the `gh-dash` extension via `gh extension install`:

```
gh extension install dlvhdr/gh-dash
```

Then, launch it via `gh dash`:

<img src="https://user-images.githubusercontent.com/6196971/198704107-6775a0ba-669d-418b-9ae9-59228aaa84d1.gif" />

### Features of note

* the bold PRs are open non-draft PRs
* the muted PRs have are draft PRs, merged PRs, or closed PRs (as indicated by
  their icon)
* the PRs are ordered by activity, so I can keep up with any ongoing relevant discussion on
  closed/merged PRs
* additional icons represent details like code review status, required status
  checks, etc.
* `?` toggles a help panel showing `gh-dash`'s supported key commands

A few key command highlights:

* `r` refreshes the dashboard (refreshes also occur automatically at a configured interval)
* `s` toggles between PR and issue views
* `h` and `j` navigate horizontally between tabbed categorizations of PRs
  and issues, within each view
* `p` toggles a preview window; `control d` and `control u` scroll the
  preview panel up and down respectivel. `c` allows you to comment directly
  from your terminal, though I rarely use this.
* `o` opens the PR in your web browser
* `y` copies the PR URL to your pastebin
* `C` checks out the PR branch locally
* `d` shows the PR diff in your terminal
* `m` merges an approved PR
* `/` allows you to interactively specify more granular search criteria

### Customization

Because `gh-dash` can be easily customized via a YAML configuration file, its
configuration can also be changed over time to serve ever-evolving team dynamics,
project priorities, and needs. For example, my current configuration can be seen
at [github.com/mdb/dotfiles/blob/main/config.yml](https://github.com/mdb/dotfiles/blob/main/config.yml),
though I'm often tuning this to better serve changing needs and nuance.

See [gh-dash documentation](https://github.com/dlvhdr/gh-dash#%EF%B8%8F-configuring) for more details.

### Related

To learn more about extending the `gh` CLI, see [Extending the gh CLI with Go](/blog/extending-the-gh-cli-with-go/).

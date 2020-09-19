---
title: Collecting Basic Team and Sprint Metrics with Git
date: 2012-08-11
tags:
- git
- metrics
thumbnail: waves_thumb.png
teaser: Leveraging git in collecting team performance metrics. Management likes numbers.
---

Per recent co-worker interest in metrics surrounding team performance, the following offer a few simple techniques for extracting team-health-oriented metrics from a git repository. Note that these are just a few basic solutions which require minimal tooling. Many alternative and more-developed solutions exist too.

##View the Total Number of Commits Per Developer within the Codebase

```bash
git shortlog -sne
```

## View the Total Number of Commits Per Developer Within a Sprint

This example assumes that the sprint began on July 1st and ended July 14th.

```bash
git shortlog -sne --after=2012-07-23 --until=today
```

## Who Made Commits Related to Tests Within a Sprint?</h4>

This example assumes that the sprint began on July 1st and ended July 14th, and that tests are contained within a <code>spec</code> directory.

```bash
git shortlog -sne --after=2012-07-01 --until=2012-07-14 spec/
```

## How Many Lines of Code Did a Developer Add and Remove Within a Sprint?</h4>

```bash
git log --author="A. Developer" --after=7-14-2012 --before=2012-07-14 --pretty=tformat: --numstat | gawk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END \
{ printf "added lines: %s removed lines : %s total lines: %s\n",add,subs,loc }'
```

## Who Worked on What Throughout a Sprint?

```bash
git shortlog --after=2012-07-01 --until=2012-07-14
```

## Examine the Total Number of Commits, Lines of Code, Files Edited, and Respective Percentage Values Per Developer Throughout the Project's History

This example uses a handy Ruby Gem called <a href="https://github.com/oleander/git-fame-rb">git_fame</a>.

```bash
gem install git_fame
git fame
```

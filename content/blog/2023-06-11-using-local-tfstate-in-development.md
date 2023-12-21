---
title: "An Updated Personal Vim Cheatsheet"
date: 2023-05-20T13:35:02Z
tags:
draft: true
thumbnail:
teaser:
---

## Problem

Certain Terraform commands may modify Terraform remote state, even outside of a
[Terraform apply](TODO). For example...

* Terraform 0.13's `0.13upgrade` command, which rewrites module source code for
  v0.13 (TODO: fact check)
* Terraform's `state replace-provider` command

## Solution

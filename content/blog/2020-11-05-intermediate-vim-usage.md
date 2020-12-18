---
title: Intermediate Vim
date: 2020-11-05
tags:
- vim
- productivity
thumbnail: night_waves_thumb.png
teaser: My notes and personal cheat sheet on a few intermediate Vim techniques.
draft: true
---

_After years of calcified Vim use, I've been trying to learn some new techniques and pave new neuro-highway. These are my notes and personal cheat sheet._

## Deleting and/or changing text

`d` ("delete") and `c` ("change") are interchangeable in commands like the following:

* `da<char>` delete around `<char>`
* `di<char>` delete inside `<char>`
* `dap` delete around paragraph
* `dat` deletes everything inside an HTML tag, including the tag
* `dit` deletes everything inside an HTML tag, excluding the tag
* `dt<char>` deletes to `<char>`
* `d/<pattern><Enter>` deletes everything up until `<pattern>`. For example: `/d/foo`
* `S` deletes the current line and pops you into insert mode

A few similar `c` ("change") examples...

* `ci<char>` deletes within the `<char>` and pops you into insert mode. For example, `ci{` deletes everything within `{...}` and pops you into insert mode.
* `ca<char>` deletes around the `<char>` and pops you into insert mode.
* `ct<char>` deletes until `<char>` and pops you into insert mode.
* `cf<char>` change forward and include `<char>`
* `c/<pattern><Enter>` changes everything up until `<pattern>`. For example: `/c/foo`

## Visually Selecting

* `vaw` visually select around word
* `vap` visually select around paragraph
* `:w /path/to/file` writes a visual selection (`shift-v` to make a visual selection) to `/path/to/file`. `:w >>/path/to/file` _appends_ the visual selection to `/path/to/file`.

## Movement

* `B` moves the cursor backwards, using whitespace as a delimiter
* `E` moves the cursor forwards, using whitespace as a delimiter
* `F<char>` moves the cursor backwards to the first instance of `<char>` in the current line
* `f<char>` moves the cursor forwards to the first instance of `<char>` in the current line

## Copy/Paste

* `y/<pattern><Enter>` yanks everything up until `<pattern>`. For example: `/y/foo`
* `Y` highlights and copies the current line; I've been `yy`-ing.
* `"+y` copies the visual selection to the clipboard for pasting outside of Vim.
* `"+Y` copies the current line to the clipboard for pasting outside of Vim.

## Spelling

* `:set spell` turns on spell checking
* `:set nospell` turns off spell checking
* `]s` jumps to the next misspelled word
* `[s` jumps to the previous misspelled word
* `z=` brings up the suggested replacements
* `zg` adds the word under the cursor to the dictionary
* `zw` undoes and removes the word from the dictionary

## Misc

* `zt` moves the line the cursor is on to the top of the view
* `zz` moves the line the cursor is on to the middle of the view
* `zb` moves the line the cursor is on to the bottom of the view
* `! <command>` opens a shell and executes the command from within Vim

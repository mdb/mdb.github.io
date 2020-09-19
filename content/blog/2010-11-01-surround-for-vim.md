---
title: Basic Overview of the Surround Plugin for Vim
date: 2010-11-01
tags:
- vim
- notes
thumbnail: blocks_thumb.png
teaser: My notes on using Vim's surround plugin.
---

Surround is a useful Vim plugin when hand-editing HTML or XML. The plugin can be downloaded via Github or the Vim website and installed by copying the `/plugin/surround.vim` file to your `~/.vim/plugin/` directory. A few of its basic commands are as follows. Note that each command is entered from within the text to be surrounded:

## Adding Surroundings

Generally, the `cs` or `ys` commands can be used to add surroundings.

Add Surrounding `<tag>` or Puncation to Word:

```bash
ysiw<tag>
csw<tag>
```

Add Surrounding to Highlighted Text From Within Visual Mode:

```bash
VS<tag>
```

Add Surrounding `<tag>` or Punctuation to Line:

```bash
yss<tag>
```

Add Surrounding to Line, Place it on a New Line, and Indent It:

```bash
ySs<tag>
ySS<tag>
```

## Changing Surroundings

Surroundings can be changed with the cs command.

Change Surrounding `<tag>`:

```bash
cst<newtag>
```

Change Surrounding Puncuation, in this Case Changing a Double Quote to a Single Quote:

```bash
cs"'
```

## Deleting Surroundings

Delete Innermost Surrounding `<tag>`:

```bash
dst
```

Delete Surrounding Quotes (Also works with parentheses, brackets, etc.):

```bash
ds"
```

Delete Text Within a `<tag>`

While this isn't a function of Surround.vim, I find it somewhat relevant to the above operations. Luckily, it’s built into Vim.

```bash
dit
```

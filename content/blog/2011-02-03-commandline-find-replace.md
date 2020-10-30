---
title: Simplified Find/Replace from the Command Line
date: 2011-02-03
tags:
- bash
- notes
thumbnail: eyes_thumb.png
teaser: An overview of a quick bash function I recently wrote.
---

I recently needed to change all instances of the text `/layout/` to `/layout_xds/` in a large collection of `css` files housed throughout multiple levels of subdirectories.

To deal with the problem, I created a bash function to serve as a shortcut wrapping my usage of `grep`, `sed`, and `uniq`. Note that I’m using Mac OS X 10.6.6.

```bash
function rep() {
  for i in `grep -R --exclude="*.svn*" "$1" * | sed s/:.*$//g | uniq`; do
    sed -i ".bak" -e "s#$1#$2#g" $i
  done
}
```

## How to Use the Function

1. Paste the above function into your `~/.bash_profile`.
1. Open Terminal.app or, if it's already open, enter `source ~/.bash_profile` to reload your profile settings.
1. `cd` to the directory where you'd like to perform the recursive find/replace.
1. Enter `rep textofind texttoreplace`. For example, to executive my above-mentioned find/replace, I entered `rep /layout/ /layout_xds/`
1. Note that the function backs up the original files with a `*.bak` file extension. After verifying that the find/replace has successfully executed, delete the `*.bak` files by running `find . -name "*.bak" -exec rm "{}" \;` from the directory where the `rep` command was run.

Props to [Jeff](https://twitter.com/javallone) for helping me on some syntax specifics.

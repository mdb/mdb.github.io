---
title: How to Exclude Files from SVN Commits
date: 2010-12-09
tags:
- subversion
- notes
- bash
thumbnail: hand_thumb.png
teaser: A bash function for working around a Subversion annoyance.
---

In Subversion, `svn commit` will commit all edited files to the central repository. In the event that I want to selectively commit only a few of my edited files, it's necessary to specify the full path to each file with `svn commit /full/path/to/filename1 /full/path/to/filename2 /full/path/to/filename3`. This can be time-consuming. Plus, it's often easier to selectively exclude files from a given commit, but Subversion doesn't offer this feature.

## The solution

I made a bash function that provides a quick way to include/exclude files from an svn commit.


```bash
function smartcommit() {
  svn stat > /tmp/svn_commits.tmp
  vim /tmp/svn_commits.tmp
  svn commit `cat /tmp/svn_commits.tmp | cut -d' ' -f2- | xargs`
  rm /tmp/svn_commits.tmp
}
```

## How to Use It

1. Paste the above function into your `~/.bash_profile`
1. Enter `smartcommit` at the command line from within a Subversion project’s directory.
1. The output of `svn stat` is printed to a new file called `svn_commits.tmp`.
1. `svn_commits.tmp` is opened in Vim.
1. Remove any lines specifiying files you DO NOT want to commit.
1. Enter `:wq` to save and quit the temporary file.
1. Proceed with the commit as normal, noting that only those files left listed in the aforementioned `svn_commits.tmp` file will be committed.
1. The `svn_commits.tmp` file is deleted.
1. A self-contained script can also be downloaded from [GitHub](https://gist.github.com/mdb/732362).

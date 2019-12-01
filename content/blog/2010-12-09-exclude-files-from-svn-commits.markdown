---
title: How to Exclude Files from SVN Commits
date: 2010-12-09
tags:
- subversion
- notes
- bash
thumbnail: ./images/thumbnails/hand_thumb.png
teaser: A bash function for working around a Subversion annoyance.
---

In Subversion, <code>svn commit</code> will commit all edited files to the central repository. In the event that I want to selectively commit only a few of my edited files, it's necessary to specify the full path to each file with <code>svn commit /full/path/to/filename1 /full/path/to/filename2 /full/path/to/filename3</code>. This can be time-consuming. Plus, it's often easier to selectively exclude files from a given commit, but Subversion doesn't offer this feature.

## The solution

I made a bash function that provides a quick way to include/exclude files from an svn commit.


```
function smartcommit() {
  svn stat > /tmp/svn_commits.tmp
  vim /tmp/svn_commits.tmp
  svn commit `cat /tmp/svn_commits.tmp | cut -d' ' -f2- | xargs`
  rm /tmp/svn_commits.tmp
}
```

## How to Use It

1. Paste the above function into your ~/.bash_profile
+ Enter smartcommit at the command line from within a Subversion project’s directory.
+ The output of svn stat is printed to a new file called svn_commits.tmp.
+ svn_commits.tmp is opened in Vim.
+ Remove any lines specifiying files you DO NOT want to commit.
+ Enter :wq to save and quit the temporary file.
+ Proceed with the commit as normal, noting that only those files left listed in the aforementioned svn_commits.tmp file will be committed.
+ The svn_commits.tmp file is deleted.
+ A self-contained script can also be downloaded from [GitHub](https://gist.github.com/mdb/732362).

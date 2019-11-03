---
title: How to Contribute to a Project on GitHub
date: 2011/08/23
tags: github, git, open source
thumbnail: github_thumb.png
teaser: A simple how-to outlining the Github fork, branch, and PR workflow.
---

A quick how-to in contributing to an open source project hosted on GitHub. These instructions assume you've already created a GitHub account and properly [set up your machine](https://help.github.com/articles/set-up-git). For more details, GitHub also publishes [similar instructions](https://help.github.com/articles/fork-a-repo).

## Set Up Your Repository

Fork a project by visiting its URL on GitHub and clicking the "Fork" button

Clone your fork to your local machine:

```
git clone git@github.com:yourUsername/project-name.git
```

Assign the original repository to a remote called "upstream" to retrieve updates from the original repository you forked:

```
cd project-name
git remote add upstream git://github.com/originalUsername/project-name.git
```

Routinely pull all the “upstream” updates to your local repository:

```
git fetch upstream
```

And merge them to your forked master:

```
git merge upstream/master
```

## Write Code

Create and check out a feature branch to house your edits:

```
git branch branchName
git checkout branchName
```

This can be shortened to:

```
git checkout -b branchName
```

Make edits and commit them:

```
git add someFile.js
git commit -m "Your commit message."
```

Push your new branch to GitHub:

```
git push origin branchName
```

Visit your forked project on GitHub and switch to your branchName branch.

Click “Pull Request” to request that your features be merged to the “upstream” master.

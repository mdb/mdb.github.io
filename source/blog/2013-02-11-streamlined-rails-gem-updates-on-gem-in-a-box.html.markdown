---
title: Streamlined Rails Gem Updates on Gem in a Box
date: 2013/02/11
tags: ruby, gems, shell
thumbnail: jumble_thumb.png
teaser: Some small shell scripts to automate manual gem downloads & uploads.
---

<strong>Problem</strong>: Per recent Ruby on Rails security patches, you need to update your Rails applications. However, because you host Rails and its related gems on a private <a href="https://github.com/cwninja/geminabox">Gem in a Box</a> gem server, it&#8217;s a bit cumbersome to manually download the necessary gems from <a href="http://rubygems.org">Rubygems.org</a>, and then upload them to your Gem in a Box gem server.

<strong>Solution</strong>: bash and curl.

<b>1.</b> List the necessary gems in a <code>gems.txt</code> file:

```
rails
actionmailer
activemodel
actionpack
activerecord
activeresource
activesupport
railties
```

<b>2.</b> Create a bash script in a <code>get_gems.sh</code> file to retrieve the gems from Rubygems.org. Note that I&#8217;ve created a <code>VERSION</code> variable specifying the desired gems&#8217; version.

```bash
#!/bin/bash

VERSION=3.2.12

for ARG in `cat $1`; do
  curl -L "http://rubygems.org/downloads/$ARG-$VERSION.gem" > "$ARG-$VERSION.gem"
done
```

<b>3.</b> Create a bash script in a <code>post_gems.sh</code> file to post the downloaded gems to your Gem in a Box. Note that I&#8217;ve created a <code>VERSION</code> variable specifying the desired gems&#8217; version here too.

```bash
#!/bin/bash

VERSION=3.2.12

for ARG in `cat $1`; do
  curl -v -X POST -F file=@$ARG-$VERSION.gem http://YOUR_GEM_IN_A_BOX_USERNAME:YOUR_PASSWORD@YOUR_GEM_IN_A_BOX.com/upload
done
```

## Usage

Download gems:

```
./get_gems.sh gems.txt
```

Upload gems:

```
./post_gems.sh gems.txt
```

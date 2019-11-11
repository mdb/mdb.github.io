---
title: Setting Up Postgres on Mac OSX with Homebrew
date: 2012/07/29
tags:
- postgres
- notes
- mac osx
thumbnail: ./images/thumbnails/computer_thumb.png
teaser: My notes on getting postgres running on Mac OS via a homebrew installation.
---

I ran into some challenges installing postgres via homebrew. I attempted to follow <a href="">these instruction</a>, as is advised by the postgres website but ran into further problems. The following steps outline how I was able to finally work around the problems. Note that I'm using Mac OSX 10.6.8.


Uninstall old versions of postgres:

```
brew rm postgresql --force
```

Update homebrew:

```
brew update
```

Install postgres:

```
brew install postgresql
```

Make a postgres directory:

```
sudo mkdir -p /usr/local/var/postgres
```

Tweak its permissions (change "YOURUSERNAME" to your username:

```
sudo chown YOURUSERNAME:admin /usr/local/var/postgres/
```

initdb:

```
initdb /usr/local/var/postgres/data
```

Add postgres to LaunchAgents directory:

```
cp /usr/local/Cellar/postgresql/9.2.4/homebrew.mxcl.postgresql.plist ~/Library/LaunchAgents
```

Load it:

```
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgres.plist
```

Start the server:

```
pg_ctl -D /usr/local/var/postgres/data -l /usr/local/var/postgres/data/server.log start
```

Note: If you receive a 'FATAL:  role "postgres" does not exist' message when doing something like <code>rake db:create</code>, you may be missing the default postres user, postgres. This can be fixed with the following command:

```
createuser -s -U $USER
```

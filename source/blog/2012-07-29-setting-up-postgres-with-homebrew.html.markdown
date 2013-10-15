---
title: Setting Up Postgres on Mac OSX with Homebrew
date: 2012/07/29
tags: postgres, notes, mac osx
thumbnail:
---

<p>I ran into some challenges installing postgres via homebrew. I attempted to follow <a href="">these instruction</a>, as is advised by the postgres website but ran into further problems. The following steps outline how I was able to finally work around the problems. Note that I'm using Mac OSX 10.6.8.</p> 

<ol>
  <li>Uninstall old versions of postgres:
    <pre><code>brew rm postgresql --force</code></pre>
  </li>
  <li>Update homebrew:
    <pre><code>brew update</code></pre>
  </li>
  <li>Install postgres:
    <pre><code>brew install postgresql</code></pre>
  </li>
  <li>Make a postgres directory:
    <pre><code>sudo mkdir -p /usr/local/var/postgres</code></pre>
  </li>
  <li>Tweak its permissions (change "YOURUSERNAME" to your username:
    <pre><code>sudo chown YOURUSERNAME:admin /usr/local/var/postgres/</code></pre>
  </li>
  <li>initdb:
    <pre><code>initdb /usr/local/var/postgres/data</code></pre>
  </li>
  <li>Add postgres to LaunchAgents directory:
    <pre><code>cp /usr/local/Cellar/postgresql/9.2.4/homebrew.mxcl.postgresql.plist ~/Library/LaunchAgents</code></pre>
  </li>
  <li>Load it:
    <pre><code>launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgres.plist</code></pre>
  </li>
  <li>Start the server:
    <pre><code>pg_ctl -D /usr/local/var/postgres/data -l /usr/local/var/postgres/data/server.log start</code></pre>
  </li>
</ol>

<p>Note: If you receive a 'FATAL:  role "postgres" does not exist' message when doing something like <code>rake db:create</code>, you may be missing the default postres user, postgres. This can be fixed with the following command:</p>

<pre><code>createuser -s -U $USER</code></pre>

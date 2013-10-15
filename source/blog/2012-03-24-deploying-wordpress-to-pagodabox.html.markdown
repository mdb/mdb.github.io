---
title: Deploying Wordpress to Pagodabox
date: 2012/03/24
tags: wordpress, cloud, pagodabox
thumbnail: pagodabox_thumb.png
---

Services such as [Heroku](http://www.heroku.com/) provide cloud deployment options for Rails, Sinatra, Django, and Node.js applications, but what about Wordpress? Pagodabox seems promising. Here's how to set up a Wordpress Pagodabox deployment workflow.

Note that these instructions are purposefully verbose in an effort to help those for whom such a workflow may be new and intimidating. Also note that these instructions assume you're using a Mac.

## Set up a local instance of Wordpress using MAMP

There's probably a fun way to do this with [Vagrant](http://www.vagrantup.com/), but MAMP will serve our purposes here.

<ol>
  <li>Install <a target="_blank" href="http://www.mamp.info/">MAMP</a> if you haven't already done so. The free version is fine.</li>
  <li>Run your MAMP Apache and MySQL servers by opening MAMP</li>
  <li>Enter your MAMP <code>htdocs</code> directory:
    <pre><code>cd /Applications/MAMP/htdocs</code></pre></li>
  <li>Download Wordpress:
    <pre><code>wget http://wordpress.org/latest.tar.gz</code></pre></li>
  <li>Unzip Wordpress:
    <pre><code>tar -xzvf latest.tar.gz</code></pre></li>
  <li>Change the name of the resulting <code>wordpress</code> directory to something more descriptive:
    <pre><code>mv wordpress your_site</code></pre></li>
  <li>Enter the MySQL command line client:
    <pre><code>/Applications/MAMP/Library/bin/mysql -u root -p</code></pre>
  </li>
  <li>Create a MySQL database for <code>your_site</code>:
    <pre><code>CREATE DATABASE your_database_name;</code></pre>
  </li>
  <li>Exit the MySQL command line client with <code>Ctrl + C</code></li>
  <li>Create a <code>wp-config.php</code> file:
    <pre><code>cp your_site/wp-config-sample.php your_site/wp-config.php</code></pre></li>
  <li>Add your local database credentials to your newly created <code>wp-config.php</code> file:
    <pre><code>define('DB_NAME', 'your_database_name');
    define('DB_USER', 'root');
    define('DB_PASSWORD', 'root');
    define('DB_HOST', 'localhost');</code></pre>
  </li>
  <li>Run the Wordpress installation script by visiting <code>http://localhost:8888/your_site/wp-admin/install.php</code> in your web browser.</li>
</ol>

## Set up your Wordpress app as a Git repository

Note that these instructions assume you have Git installed.

<ol>
  <li>Make your Wordpress app a Git repository by entering the following from within <code>/Applications/MAMP/htdocs/your_site</code>:
    <pre><code>git init</code></pre>
  </li>
  <li>Add all of <code>your_site</code>'s files to your repository:
    <pre><code>git add .</code></pre>
  </li>
  <li>Commit your code:
    <pre><code>git commit -m "First commit."</code></pre>
  </li>
</ol>

## Set up your Wordpress app for Pagodabox deployment

<ol>
  <li>Create a Boxfile. This is the Pagodabox config file:
    <pre><code>touch Boxfile</code></pre>
  </li>
  <li>Add the following to your Boxfile to set up a basic Wordpress configuration:
    <pre><code>web1: #component type & number
        name: wp #component settings
        shared_writable_dirs:
            - wp-content/uploads
    </code></pre>
  </li>
  <li>Save and commit your Boxfile.</li>
</ol>

## Set up your Pagodabox account

Follow the instructions provided by <a target="_blank" href="https://dashboard.pagodabox.com/account/register">Pagodabox</a>. In short, you'll create an account, create an app for <code>your_site</code>, generate an SSH key if you don't already have one, and provide Pagodabox your SSH key.

## Deploy your Wordpress app to Pagodabox

<ol>
  <li>Declare a <code>pagodabox</code> remote repository:
    <pre><code>git remote add pagoda git@git.pagodabox.com:your_site.git</code></pre>
  </li>
  <li>Push your code to Pagodabox:
    <pre><code>git push pagodabox master</code></pre>
  </li>
</ol>

At this point, you can vew your site at http://your_site.pagodabox.com, although you should see an "Error Connecting to Database" message in your browser. This is because <code>your_site</code> isn't yet wired up to a Pagodabox MySQL database.</p>

## Set up a Pagodabox MySQL database

<ol>
  <li>Log into Pagodabox, visit the dashboard for your Wordpress app, and click "Add Database."</li> 
  <li>Click "Environment vars" and add a <code>PLATFORM = PAGODABOX</code> variable.</li>
  <li>Because Pagodabox automatically houses your database credentials in environment variables, you can now connect your Wordpress app to your local database while working locally and to your Pagodabox database when it's deployed to Pagodabox. To connect to different databases based on environment, open your <code>wp-config.php</code> file and replace your local database credentials with the following:
    <pre><code>if (isset($_SERVER['PLATFORM']) && $_SERVER['PLATFORM'] == 'PAGODABOX') {
      define('DB_NAME', $_SERVER['DB1_NAME']);
      define('DB_USER', $_SERVER['DB1_USER']);
      define('DB_PASSWORD', $_SERVER['DB1_PASS']);
      define ('DB_HOST', $_SERVER['DB1_HOST'] . ':' . $_SERVER['DB1_PORT']);
    }
    else {
      define('DB_NAME', 'your_database_name');
      define('DB_USER', 'root');
      define('DB_PASSWORD', 'root');
      define('DB_HOST', 'localhost');
    }
    </code></pre>
  </li>
  <li>Commit your code and push your Wordpress app to Pagodabox:
    <pre><code>git add wp-config.php
    git commit -m "Wordpress now detects environment and connects to the appropriate database accordingly."
    git push pagodabox master
    </code></pre>
  </li>
  <li>Run the Wordpress installation script on Pagodabox by visiting <code>http://your_site.pagodabox.com/wp-admin/install.php</code>.</li>
</ol>

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

<b>1.</b> Install <a target="_blank" href="http://www.mamp.info/">MAMP</a> if you haven't already done so. The free version is fine.

<b>2.</b> Run your MAMP Apache and MySQL servers by opening

<b>3.</b> Enter your MAMP <code>htdocs</code> directory:

```
cd /Applications/MAMP/htdocs
```

<b>4.</b> Download Wordpress:

```
wget http://wordpress.org/latest.tar.gz
```

<b>5.</b> Unzip Wordpress:

```
tar -xzvf latest.tar.gz
```

<b>6.</b> Change the name of the resulting <code>wordpress</code> directory to something more descriptive:

```
mv wordpress your_site
```

<b>7.</b> Enter the MySQL command line client:

```
/Applications/MAMP/Library/bin/mysql -u root -p
```

<b>8.</b> Create a MySQL database for <code>your_site</code>:

```
CREATE DATABASE your_database_name;
```

<b>9.</b> Exit the MySQL command line client with <code>Ctrl + C</code>

<b>10.</b> Create a <code>wp-config.php</code> file:

```
cp your_site/wp-config-sample.php your_site/wp-config.php
```

<b>11.</b> Add your local database credentials to your newly created <code>wp-config.php</code> file:

```php
define('DB_NAME', 'your_database_name');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
```

<b>12.</b> Run the Wordpress installation script by visiting <code>http://localhost:8888/your_site/wp-admin/install.php</code> in your web browser.</li>

## Set up your Wordpress app as a Git repository

Note that these instructions assume you have Git installed.

<b>1.</b> Make your Wordpress app a Git repository:

```
cd your_site
git init
```

<b>2.</b> Add all of <code>your_site</code>'s files to your repository:

```
git add .
```

<b>3.</b>Commit your code:

```
git commit -m "First commit."</code></pre>
```

## Set up your Wordpress app for Pagodabox deployment

<b>4.</b>Create a Boxfile. This is the Pagodabox config file:

```
touch Boxfile
```

Add the following to your Boxfile to set up a basic Wordpress configuration:

```
web1: #component type & number
name: wp #component settings
shared_writable_dirs:
  - wp-content/uploads
```

<b>5.</b> Save and commit your Boxfile.

## Set up your Pagodabox account

Follow the instructions provided by <a target="_blank" href="https://dashboard.pagodabox.com/account/register">Pagodabox</a>. In short, you'll create an account, create an app for <code>your_site</code>, generate an SSH key if you don't already have one, and provide Pagodabox your SSH key.

## Deploy your Wordpress app to Pagodabox

<b>1.</b> Declare a <code>pagodabox</code> remote repository:

```
git remote add pagoda git@git.pagodabox.com:your_site.git
```

<b>2.</b> Push your code to Pagodabox:

```
git push pagodabox master
```

At this point, you can vew your site at http://your_site.pagodabox.com, although you should see an "Error Connecting to Database" message in your browser. This is because <code>your_site</code> isn't yet wired up to a Pagodabox MySQL database.

## Set up a Pagodabox MySQL database

<b>1.</b> Log into Pagodabox, visit the dashboard for your Wordpress app, and click "Add Database."
<b>2.</b> Click "Environment vars" and add a <code>PLATFORM = PAGODABOX</code> variable.
<b>3.</b> Because Pagodabox automatically houses your database credentials in environment variables, you can now connect your Wordpress app to your local database while working locally and to your Pagodabox database when it's deployed to Pagodabox. To connect to different databases based on environment, open your <code>wp-config.php</code> file and replace your local database credentials with the following:

```php
if (isset($_SERVER['PLATFORM']) && $_SERVER['PLATFORM'] == 'PAGODABOX') {
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
```

<b>4.</b> Commit your code and push your Wordpress app to Pagodabox:

```
git add wp-config.php
git commit -m "Wordpress now detects environment and connects to the appropriate database accordingly."
git push pagodabox master
```

<b>5.</b> Run the Wordpress installation script on Pagodabox by visiting <code>http://your_site.pagodabox.com/wp-admin/install.php</code>.</li>

---
title: Deploying Wordpress to Pagodabox
date: 2012-03-24
tags:
- wordpress
- cloud
- pagodabox
thumbnail: pagodabox_thumb.png
teaser: A beginner's guide to deploying a Wordpress app to Pagodabox's cloud service.
---

Services such as [Heroku](http://www.heroku.com/) provide cloud deployment options for Rails, Sinatra, Django, and Node.js applications, but what about Wordpress? Pagodabox seems promising. Here's how to set up a Wordpress Pagodabox deployment workflow.

Note that these instructions are purposefully verbose in an effort to help those for whom such a workflow may be new and intimidating. Also note that these instructions assume you're using a Mac.

## Set up a local instance of Wordpress using MAMP

There's probably a fun way to do this with [Vagrant](http://www.vagrantup.com/), but MAMP will serve our purposes here.

1. Install [MAMP](http://www.mamp.info/") if you haven't already done so. The free version is fine.

2. Run your MAMP Apache and MySQL servers by opening

3. Enter your MAMP `htdocs` directory:

```bash
cd /Applications/MAMP/htdocs
```

4. Download Wordpress:

```bash
wget http://wordpress.org/latest.tar.gz
```

5. Unzip Wordpress:

```bash
tar -xzvf latest.tar.gz
```

6. Change the name of the resulting `wordpress` directory to something more descriptive:

```bash
mv wordpress your_site
```

7. Enter the MySQL command line client:

```bash
/Applications/MAMP/Library/bin/mysql -u root -p
```

8. Create a MySQL database for `your_site`:

```bash
CREATE DATABASE your_database_name;
```

9. Exit the MySQL command line client with `Ctrl + C`

10. Create a `wp-config.php` file:

```bash
cp your_site/wp-config-sample.php your_site/wp-config.php
```

11. Add your local database credentials to your newly created `wp-config.php` file:

```php
define('DB_NAME', 'your_database_name');
define('DB_USER', 'root');
define('DB_PASSWORD', 'root');
define('DB_HOST', 'localhost');
```

12. Run the Wordpress installation script by visiting `http://localhost:8888/your_site/wp-admin/install.php` in your web browser.

## Set up your Wordpress app as a Git repository

Note that these instructions assume you have Git installed.

1. Make your Wordpress app a Git repository:

```bash
cd your_site
git init
```

2. Add all of `your_site`'s files to your repository:

```bash
git add .
```

3.Commit your code:

```bash
git commit -m "First commit."
```

## Set up your Wordpress app for Pagodabox deployment

4.Create a Boxfile. This is the Pagodabox config file:

```bash
touch Boxfile
```

Add the following to your Boxfile to set up a basic Wordpress configuration:

```bash
web1: #component type & number
name: wp #component settings
shared_writable_dirs:
  - wp-content/uploads
```

5. Save and commit your Boxfile.

## Set up your Pagodabox account

Follow the instructions provided by [Pagodabox](https://dashboard.pagodabox.com/account/register). In short, you'll create an account, create an app for `your_site`, generate an SSH key if you don't already have one, and provide Pagodabox your SSH key.

## Deploy your Wordpress app to Pagodabox

1. Declare a `pagodabox` remote repository:

```bash
git remote add pagoda git@git.pagodabox.com:your_site.git
```

2. Push your code to Pagodabox:

```bash
git push pagodabox master
```

At this point, you can vew your site at `http://your_site.pagodabox.com`, although you should see an "Error Connecting to Database" message in your browser. This is because `your_site` isn't yet wired up to a Pagodabox MySQL database.

## Set up a Pagodabox MySQL database

1. Log into Pagodabox, visit the dashboard for your Wordpress app, and click "Add Database."
2. Click "Environment vars" and add a `PLATFORM = PAGODABOX` variable.
3. Because Pagodabox automatically houses your database credentials in environment variables, you can now connect your Wordpress app to your local database while working locally and to your Pagodabox database when it's deployed to Pagodabox. To connect to different databases based on environment, open your `wp-config.php` file and replace your local database credentials with the following:

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

4. Commit your code and push your Wordpress app to Pagodabox:

```bash
git add wp-config.php
git commit -m "Wordpress now detects environment and connects to the appropriate database accordingly."
git push pagodabox master
```

5. Run the Wordpress installation script on Pagodabox by visiting `http://your_site.pagodabox.com/wp-admin/install.php`.

---
title: Using South on a Heroku-hosted Django Project
date: 2012-02-18
tags:
- django
- heroku
- south
thumbnail: cloud_thumb.png
teaser: How to add new fields to an existing, Heroku-hosted Django project's database.
---

**Problem**: You need to add new fields to the admin of a Django project hosted on Heroku but don't want to destroy data by running `syncdb` on your Heroku-hosted database.

**Solution**: [South](http://south.aeracode.org/docs/about.html).

These instructions assume you're working in a clean checkout of a Heroku project named `heroku_project`, which contains a Django project named `django_project`, which contains an app named `django_app`. You need to add a new admin field to `django_app`.


1. Open `settings.py` and add 'south' to your list of `INSTALLED_APPS`

1. Run syncdb locally:
    ```bash
    python django_project/manage.py syncdb
    ```

1. Convert your project to use South:
    ```bash
    python django_project/manage.py convert_to_south django_app
    ```

1. Add some new fields to `django_project/django_app/models.py`

1. Set up the schema:
    ```bash
    python django_project/manage.py schemamigration django_app --auto
    ```

1. Perform the migration:
    ```bash
    python django_project/manage.py migrate django_app
    ```

1. Add `South` Heroku project's `requirements.txt` file. For example:
    ```bash
    South==0.7.3
    ```

1. Add the South `django_project/migrations` directory to version control and commit all your changes.

1. Push your changes to Heroku:
    ```bash
    git push heroku master
    ```

1. Run `syncdb` on Heroku:
    ```bash
    heroku run bin/python django_project/manage.py syncdb
    ```

1. Convert your Heroku instance of `django_app` to use South
    ```bash
    heroku run bin/python django_project/manage.py convert_to_south django_app
    ```

1. Perform the migration:
    ```bash
    heroku run bin/python django_project/manage.py migrate django_app
    ```

Note that you will have to repeat the `django_app`-specific steps for each Django app you modify.

And what if you make further changes to `django_project/django_app/models.py`?


1. Make changes to `django_project/some_app/models.py`

1. Create the south migration file:
    ```bash
    python django_project/manage.py schemamigration some_app --auto
    ```

1. Migrate locally:
    ```bash
    python django_project/manage.py migrate some_app
    ```

1. Commit your changes and push them to Heroku

1. Migrate on Heroku:
    ```bash
    heroku run bin/python django_project/manage.py migrate some_app
    ```

Gratitude to [Casey Thomas](http://www.caseypthomas.org/blog/managing-a-django-or-any-database-on-heroku) for the South knowledge-sharing.

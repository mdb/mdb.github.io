---
title: Using South on a Heroku-hosted Django Project
date: 2012/02/18
tags:
- django
- heroku
- south
thumbnail: ./images/thumbnails/cloud_thumb.png
teaser: How to add new fields to an existing, Heroku-hosted Django project's database.
---

<b>Problem</b>: You need to add new fields to the admin of a Django project hosted on Heroku but don't want to destroy data by running <code>syncdb</code> on your Heroku-hosted database.

<b>Solution</b>: <a href="http://south.aeracode.org/docs/about.html">South</a>

These instructions assume you're working in a clean checkout of a Heroku project named <code>heroku_project</code>, which contains a Django project named <code>django_project</code>, which contains an app named <code>django_app</code>. You need to add a new admin field to <code>django_app</code>.

<ol>
  <li>Open <code>settings.py</code> and add 'south' to your list of <code>INSTALLED_APPS</code></li>
  <li>Run syncdb locally:
    <pre><code>python django_project/manage.py syncdb</code></pre>
  </li>
  <li>Convert your project to use South:
    <pre><code>python django_project/manage.py convert_to_south django_app</code></pre>
  </li>
  <li>Add some new fields to <code>django_project/django_app/models.py</code></li>
  <li>Set up the schema:
    <pre><code>python django_project/manage.py schemamigration django_app --auto</code></pre>
  </li>
  <li>Perform the migration:
    <pre><code>python django_project/manage.py migrate django_app</code></pre>
  </li>
  <li>Add <code>South</code> Heroku project's <code>requirements.txt</code> file. For example:
    <pre><code>South==0.7.3</code></pre>
  </li>
  <li>Add the South <code>django_project/migrations</code> directory to version control and commit all your changes.</li>
  <li>Push your changes to Heroku:
    <pre><code>git push heroku master</code></pre>
  </li>
  <li>Run <code>syncdb</code> on Heroku:
    <pre><code>heroku run bin/python django_project/manage.py syncdb</code></pre>
  </li>
  <li>Convert your Heroku instance of <code>django_app</code> to use South
  <pre><code>heroku run bin/python django_project/manage.py convert_to_south django_app</code></pre>
  </li>
  <li>Perform the migration:
    <pre><code>heroku run bin/python django_project/manage.py migrate django_app</code></pre>
  </li>
</ol>

Note that you will have to repeat the <code>django_app</code>-specific steps for each Django app you modify.

And what if you make further changes to <code>django_project/django_app/models.py</code>?

<ol>
  <li>Make changes to <code>django_project/some_app/models.py</code></li>
  <li>Create the south migration file:
    <pre><code>python django_project/manage.py schemamigration some_app --auto</code></pre>
  </li>
  <li>Migrate locally:
    <pre><code>python django_project/manage.py migrate some_app</code></pre>
  </li>
  <li>Commit your changes and push them to Heroku</li>
  <li>Migrate on Heroku:
    <pre><code>heroku run bin/python django_project/manage.py migrate some_app</code></pre>
  </li>
</ol>

Gratitude to <a href="http://www.caseypthomas.org/blog/managing-a-django-or-any-database-on-heroku">Casey Thomas</a> for the South knowledge-sharing.

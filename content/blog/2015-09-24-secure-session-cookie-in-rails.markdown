---
title: Secure Session Cookie in Rails over HTTPS
date: 2015/09/24
tags:
- rails
- apache
- https
thumbnail: ./images/thumbnails/impossible_shape.png
teaser: How to ensure the secure flag is present in your Apache-fronted Rails app's session cookies.
---

The secure flag can be set by an application server when sending a cookie within an HTTP response. By setting the secure flag, an HTTP client &mdash; such as a web browser &mdash; prevents cookie transmission unless the response is securely encrypted over HTTPS.

However, many web applications redirect `http://` to `https://`, and many Ruby on Rails applications are fronted by a web server such as Ngnix or Apache. Often, `HTTPS` is terminated at the Nginx/Apache layer. Given such an architecture, consider the following problematic behavior through which a Ruby on Rails session cookie could be transmitted insecurely in clear text:

1. user types `http://example.com` into browser address bar
2. browser makes request to `http://example.com`
3. browser receives 301 response w/ `https://example.com` specified as `Location` header; no session cookie is present/set
4. browser makes request to `https://example.com`
5. browser receives response with session cookie present/set; the secure flag is absent from the cookie
6. user types `http://example.com` into browser address bar
7. browser makes request to `http://example.com`
8. browser receives 301 response with `https://example.com` specified as `Location` header; step #5 session cookie is present/set was transmitted in clear text because the secure flag was absent in step #5.

In Rails, calling `Rails.application.config.session_store` with `secure: true` in `config/initializers/session_store.rb` informs the Rails application to add the secure flag, but Rails will only do so if SSL is terminated at the application _or_ if the Rails-fronting web server at which SSL is terminated &ndash; Nginx or Apache in the above example &mdash; adds an `X-Forwarded-Proto` header whose value is `https`.

For example, to do so in Apache, add the following to the Apache config file controlling your site:

```
RequestHeader set X-Forwarded-Proto "https"
```

And add the following to your Rails app's `config/initializers/session_store.rb`:

```
Rails.application.config.session_store :cookie_store,
                                       :key => '_your_app_name_session',
                                       :secure => ENV['RAILS_ENV'] != 'development'
```

Note that this requires an application restart to take effect.

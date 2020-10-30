---
title: OAuth2 in Plain Words
date: 2020-10-08
tags:
- oauth2
- golang
thumbnail: night_waves_thumb.png
teaser: A simple explanation of OAuth2
draft: true
---

What's OAuth2 and how does it work? There's a lotta info out there. Here's plain explanation:

1. A user selects the provider through whom they'd like to sign in. For example: Instagram, Google, GitHub.
1. The user is redicrected to the provider's website -- using a URL that includes an ID identifying the application from which the user came -- and are asked to grant login permission to the application.
1. The user signs in to the provider and accepts the permissions requested by the application.
1. The provider redirects back to the application using a URL that includes a request code.
1. The application sends the code to the provider, which responds by sending back an authentication token.
1. The application uses the token to make authorized requests to the provider to retrieve provider data, such as Instagram images, GitHub activity, or a profile image URL.

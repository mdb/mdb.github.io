---
title: Apache Persistant Connection Problems
date: 2015/10/18
thumbnail: texture_thumb.png
tags: apache, operations, performance
---

Problem: Apache worker thread pool is exhausted; server CPU consumption is high.

Solution: reduce the Apache `KeepAliveTimeout` from its 15 second default (disclaimer: maybe, depending on circumstances).

## Background

HTTP keep-alive functionality seeks to improve efficiency. In effect, HTTP keep-alive &mdash; also referred to as _HTTP persistant connection_ and _HTTP connection reuse_ allows the use of a single TCP connection to send and receive multiple HTTP requests and responses.

Keep-alive reduces the latency associated with opening a new TCP connection for each HTTP request. It also reduces server CPU usage: by reusing an open connection, the server isn't required to utilize CPU resources necessary to open a new TCP connection (and handle HTTPS, if relevant).

Apache offers three settings through which HTTP keep-alive can be tuned:

* `KeepAlive` &mdash; enables/disables HTTP keep-alive functionality
* `MaxKeepAliveRequests` &mdash; the maximum requests a single open connection can serve
* `KeepAliveTimeout` &mdash; the duration in seconds the server should wait for subsequent requests from a connected client before closing the connection. By default, 15 seconds.

## The Apache problem

The Apache web server offers a `KeepAliveTimeout` default of 15 seconds. However, when individual clients don't require 15 seconds of connection persistance, the lengthy timeout is unnecessarily memory-intensive for the server. In such a problematic scenario, the creation of many Apache processes &mdash; one per connection &mdash; occupies RAM waiting for subsequent client requests inside a too-generous 15 second window. This can result in Apache worker thread exhaustion under moderate traffic.

Access log analysis should offer insight. How frequently do individual clients perform requests? How much traffic is Apache serving? If worker thread usage consistently exceeds the request count inside a given window of time, `KeepAliveTimeout` may be too high. This is further substantiated if individual clients rarely perform multiple requests inside a 15 second window or if, for example, clients perform multiple requests inside an initial 5 seconds and don't perform subsequent requests for more than 10 seconds.

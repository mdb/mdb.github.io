---
title: HTTP Middleware in Go with httptest.ResponseRecorder
date: 2021-02-13
tags:
- http
- golang
thumbnail: coffee_mug_thumb.png
teaser: A technique for creating Go HTTP middleware.
---

_A technique for creating "post-process" HTTP middleware in Go._

## Problem

You need to add a bit of extra "post-process" functionality or logic beyond what an existing [http.Handler](https://golang.org/pkg/net/http/#Handler) offers, but don't have the ability to modify the existing handler, perhaps because it's provided by a third party package. For example, how might you add an HTTP response header to the handler's HTTP response before the response is sent to the client?

While the [http.Handler wrapper technique](https://medium.com/@matryer/the-http-handler-wrapper-technique-in-golang-updated-bc7fbcffa702) is commonly utilized to invoke code before and/or after invoking an `http.Handler`'s `ServeHTTP`, method, it doesn't enable post-processing the `http.Handler`'s handling of the `http.ResponseWriter`.

In other words, how could you write some _middleware_ that wraps and adds to an `http.Handler`'s existing functionality _after_ the `http.Handler` has already processed a request and produced an HTTP response, thereby _modifying_ the HTTP response before it's sent to the client?

## Solution

Use [httptest.ResponseRecorder](https://golang.org/pkg/net/http/httptest/#ResponseRecorder) to record the `http.Handler`'s response; this provides a hook through which the response can be modified as needed.

## A basic example

In the following example, `WrappedHandler` invokes the `http.Handler` it's passed, but uses an [httptest.ResponseRecorder](https://golang.org/pkg/net/http/httptest/#ResponseRecorder) to record the `http.Handler`'s response and add an `X-Foo` header before writing to the the `http.ResponseWriter`:

```golang
// WrappedHandler uses the handler it's passed, but
// adds an 'X-Foo: bar' header to the response.
func WrappedHandler(handler http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Use an httptest.ResponseRecorder to invoke handler
        // and record its response:
        // https://golang.org/pkg/net/http/httptest/#ResponseRecorder
        rec := httptest.NewRecorder()

        // Invoke handler with the http.ResponseRecorder
        handler.ServeHTTP(rec, r)

        // Store the response in a 'res' var
        res := rec.Result()

        // Copy the recorded headers to the http.ResponseWriter
        for k, v := range res.Header {
            k = http.CanonicalHeaderKey(k)
            w.Header()[k] = v
        }

        // Set the custom 'X-Foo' header
        w.Header()["X-Foo"] = "bar"

        // Write the recorded status code to the http.ResponseWriter
        w.WriteHeader(res.StatusCode)

        // Write the recorded body to the http.ResponseWriter
        w.Write(rec.Body.Bytes())
    })
}
```

## A real world example

[Concourse pull request 5897](https://github.com/concourse/concourse/pull/5897/files) introduces what is perhaps a more realistic example via its [token.StoreAccessToken](https://github.com/concourse/concourse/pull/5897/files#diff-47f1a1fcbe74de4be3af39c657cec8111bcc235be0ca43b1c076f3a460585136R38) function.

`token.StoreAccessToken` provides middleware that records `/sky/issuer/token` requests' response from a [dex](https://github.com/concourse/dex/) `server.Server` and does some stuff with its HTTP response, including storing some of the response data in the Concourse database, as well as modifying the `access_token` field in its JSON response body.

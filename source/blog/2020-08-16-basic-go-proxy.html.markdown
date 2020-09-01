---
title: How to Make a Basic Reverse Proxy in Go
date: 2020/08/16
tags: golang, go
thumbnail: TODO.png
teaser: An intro to building a basic reverse proxy in Go
published: false
---

In networks, a reverse proxy retrieves resources on behalf of a client from one or more servers, returning the resources to the client as if they originated from the proxy server. An application load balancer is a common example of a reverse proxy.

The [Go](https://golang.org/) programming language's [`net/http/httputil`](https://golang.org/pkg/net/http/httputil/) package makes creating a reverse proxy in Go simple.

```golang
package main

import (
  "bytes"
  "fmt"
  "io/ioutil"
  "net/http"
  "net/http/httputil"
  "net/url"
)

func serveReverseProxy(res http.ResponseWriter, req *http.Request) {
  url, _ := url.Parse("http://www.mikeball.info")

  proxy := httputil.NewSingleHostReverseProxy(url)

  // Update request headers to allow for SSL redirection
  req.URL.Host = url.Host
  req.URL.Scheme = url.Scheme
  req.Header.Set("X-Forwarded-Host", req.Header.Get("Host"))
  req.Host = url.Host

  proxy.ServeHTTP(res, req)
}

func main() {
  http.HandleFunc("/", serveReverseProxy)
  if err := http.ListenAndServe(":1330", nil); err != nil {
    panic(err)
  }
}
```

To run the proxy:

```
go run main.go
```

---
title: Channels in Go
date: 2018/01/09
tags:
- golang
- go
- concurrency
thumbnail: roller_skating_thumb.png
teaser: A brief intro to Go concurrency through channels and goroutines.
---

Through `goroutines` and `channels`, Go offers mechanisms for concurrent programming. A `goroutine` is a concurrent function execution, while a `channel` offers a communication mechanism through which one `goroutine` can pass values of a specific type to another `goroutine`.

For example, the following code performs three HTTP requests concurrently, reports back the request URL, the request response time, and its HTTP response status code for each request, and also the total time spent executing the program. In this example, the `channel` receives a string summarizing the URL, response time, and status code details for each concurrent request, while the `main` function prints each string sent to the `channel`. The code illustrates that the total time spent executing the program is less than the sum of the times spent waiting for each individual HTTP response, as the HTTP requests are performed concurrently.

```go
package main

import (
  "fmt"
  "net/http"
  "time"
)

func main() {
  start := time.Now()
  // create a channel of strings:
  ch := make(chan string)
  urls := []string{
    "http://mikeball.info",
    "http://mikeball.me",
    "http://github.com/mdb",
  }

  // Call `fetch` in a new goroutine for each URL in `urls`:
  for _, url := range urls {
    go fetch(url, ch)
  }

  // Receive and print each string sent to the `ch` channel from `fetch`:
  for range urls {
    fmt.Println(<-ch)
  }

  // Print the total seconds spent in `main`
  // The individual request response times reported by `fetch` equal a sum greater than the total
  // seconds spent in `main`, thus illustrating that the `fetch` requests occurred concurrently.
  fmt.Printf("Total time: %.2fs\n", time.Since(start).Seconds())
}

func fetch(url string, ch chan<- string) {
  start := time.Now()
  resp, err := http.Get(url)
  if err != nil {
    // Send an error to the `ch` channel if one is encountered:
    ch <- fmt.Sprint(err)
    return
  }
  secs := time.Since(start).Seconds()
  // Send a summary string to the `ch` channel containing the URL, its request response time, and its HTTP status code
  ch <- fmt.Sprintf("%s \t %.2fs \t %d", url, secs, resp.StatusCode)
}
```

Example output:

```
$ go run fetch.go
http://mikeball.me       0.26s   200
http://mikeball.info     0.38s   200
http://github.com/mdb    0.53s   200
Total time: 0.53s
```

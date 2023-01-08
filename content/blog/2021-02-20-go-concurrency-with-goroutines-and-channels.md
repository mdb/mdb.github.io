---
title: Go Concurrency With Goroutines and Channels
date: 2021-02-20
tags:
- golang
- programming
- concurrency
thumbnail: summer_mountains_thumb.png
teaser: An(other) introduction to Go concurrency, goroutines, and channels.
---

_Some introductory notes on Go concurrency, goroutines, and channels, largely serving as a slightly-more-indepth supplement to [a brief 2018 overview and example](/blog/channels-in-go/)._

## Goroutines

Normally, calling a function &mdash; `foo()`, for example &mdash; is a _blocking_ operation. This means that program execution waits for it to finish before proceeding.

However, invoking a function with the `go` keyword &mdash; `go foo()`, for example &mdash; is _non-blocking_. When invoked as `go foo()`, Go runs `foo()` as a separate task managed by Go. The separate task is called a [_goroutine_](https://golang.org/doc/effective_go#goroutines). The original Go task &mdash; the one Go creates when operating on a program's `main` function &mdash; is called the _main goroutine_. In this case, when `foo` is invoked as `go foo()`, the main goroutine does not wait for `foo()` to finish; it proceeds, as `foo()` runs _concurrently_ in a separate _goroutine_.

## Channels

In Go, the `chan` keyword defines a _channel_. According to [A Tour of Go](https://tour.golang.org/concurrency/2), "Channels are a typed conduit through which you can send and receive values with the channel operator, `<-`." A channel can transport data of only one type.

The `<-` operator indicates the channel direction: either _send_ or _receive_. If no `<-` direction is specified, the channel is _bi-directional_.

For example:

```golang
chan Foo      // can be used to send & receive values of type Foo
chan<- string // send only; can be used to send strings
<-chan int    // receive only; can be used to receive ints
```

So, in other words, the `channel <-` syntax sends a value to a channel, while the `<- channel` syntax receives a value from a channel:

```golang
ch <- s   // Send s to channel ch.
s := <-ch // Receive from ch and assign the value to s.
```

`make` is used to create a channel:

```golang
strCh := make(chan string) // a channel of strings
intCh := make(chan int)    // a channel of ints
```

The _unbuffered_ channels above only accept sends (`strCh <-`, for example) if a corresponding receive (`<- strCh`) is ready to receive the sent value. However, channels can also be _buffered_. Buffered channels accept a limited number of values without a corresponding receiver. Buffered channels are created by specifying a capacity when creating the channel:

```golang
strCh := make(chan string, 100) // a buffered channel of capacity 100
intCh := make(chan int, 100)    // a buffered channel of capacity 100
```

In other words, sends and receives to unbuffered channels block until the other side is ready. Sends to a buffered channels block only when the buffer is full. Receives block only when the buffer is empty.

`close` is used to close a channel, indicating no more values will be sent. For example:

```golang
close(strCh) // close strCh
close(intCh) // close intCh
```

Receivers can check whether a channel is closed like so:

```golang
s, ok := <-ch

if ok {
  fmt.Println("s channel is not closed")
} else {
  fmt.Println("s channel is closed")
}
```

(Although, closing is really only necessary if the receiver must be explicitly told no more values will come, as might be necessary to terminate a loop, for example.)

## Using channels to communicate between goroutines

Channels offer a mechanism through which separate goroutines can communicate, in effect offering a useful construct for _concurrent_ programming. Performing multiple concurrent HTTP requests offers a common use case. A program that performs the HTTP requests _serially_ &mdash; one at a time &mdash; is slower than one that performs the HTTP requests concurrently.

### A non-concurrent Go program

For example, the following non-concurrent program &mdash; let's call it `fetch_urls.go` &mdash; performs a series of HTTP requests, reports the time it took to perform each request, and reports the program's total execution time:

```golang
package main

import (
	"fmt"
	"net/http"
	"time"
)

// main is the main goroutine
func main() {
	// Save the start time to a variable
	start := time.Now()

	// Create a slice of URLs to request
	urls := []string{
		"http://mikeball.info",
		"http://mikeball.me",
		"http://github.com/mdb",
	}

	// Call `fetch` with each URL in `urls` and print the results
	for _, url := range urls {
		fmt.Println(fetch(url))
	}

	// Print the total seconds spent in `main`
	fmt.Printf("Total time: %.2fs\n", time.Since(start).Seconds())
}

// fetch performs an HTTP request to the URL it's passed.
//
// If it does not encounter an error performing the HTTP
// request, returns a string like the following,
// reporting the total seconds required to perform the
// request, as well as the response status code:
//
// "http://foo.com  0.26s  200"
//
// If it encounters an error, it returns a string like the
// following:
//
// "http://foo.com request encountered error: some error"
func fetch(url string) string {
	start := time.Now()

	resp, err := http.Get(url)
	if err != nil {
		return fmt.Sprintf("%s request enountered error: %s", url, err.Error())
	}

	secs := time.Since(start).Seconds()

	// Return a summary string containing the URL, its request response time, and its HTTP status code
	return fmt.Sprintf("%s \t %.2fs \t %d", url, secs, resp.StatusCode)
}
```

When the program is run via `go run fetch_urls.go`, it prints the following:

```bash
go run fetch_urls.go
http://mikeball.info     0.96s   200
http://mikeball.me       0.35s   200
http://github.com/mdb    0.92s   200
Total time: 2.23s
```

Note that the program's total execution time of 2.23s is the sum of the times consumed by each HTTP request.

### A concurrent Go program

So, how might channels and goroutines be used to perform multiple concurrent HTTP requests? The following offers an example &mdash; similar to one I [wrote about in 2018](/blog/channels-in-go/) &mdash; illustrating how the serial version of `fetch_urls.go` could be refactored to leverage concurrency:

```golang
package main

import (
	"fmt"
	"net/http"
	"time"
)

// main is the main goroutine
func main() {
	// Store the current time in a variable
	start := time.Now()

	// Create a channel of strings
	ch := make(chan string)

	urls := []string{
		"http://mikeball.info",
		"http://mikeball.me",
		"http://github.com/mdb",
	}

	// Call `fetch` in a new goroutine for each URL in `urls`
	for _, url := range urls {
		go fetch(url, ch)
	}

	// Receive and print each string sent to the `ch` channel from `fetch`
	for range urls {
		fmt.Println(<-ch)
	}

	// Print the total seconds spent in `main`
	// The individual request response times reported by `fetch` equal a sum greater than the total
	// seconds spent in `main`, thus illustrating that the `fetch` requests occurred concurrently.
	fmt.Printf("Total time: %.2fs\n", time.Since(start).Seconds())
}

// fetch performs an HTTP request to the URL it's passed.
//
// If it does not encounter an error performing the HTTP
// request, it sends a string like the following to the
// ch channel it's passed, reporting the total seconds
// required to perform the request, as well as the response
// status code:
//
// "http://foo.com  0.26s  200"
//
// If it encounters an error, it sends a string like the
// following too the ch channel it's passed:
//
// "http://foo.com request encountered error: some error"
func fetch(url string, ch chan<- string) {
	// Store the start time in a variable
	start := time.Now()

	resp, err := http.Get(url)
	if err != nil {
		ch <- fmt.Sprintf("%s request enountered error: %s", url, err.Error())

		return
	}

	// Store the seconds since start time in a variable
	secs := time.Since(start).Seconds()

	// Send a summary string to the `ch` channel containing the URL, its request response time, and its HTTP status code
	ch <- fmt.Sprintf("%s \t %.2fs \t %d", url, secs, resp.StatusCode)
}
```

Now, when the program is run via `go run fetch_urls.go`, it prints the following:

```bash
go run fetch_urls.go
http://mikeball.info     0.33s   200
http://mikeball.me       0.34s   200
http://github.com/mdb    0.93s   200
Total time: 0.93s
```

Note that the program's total execution time of 0.93s is _less than_ the sum of the times consumed by each HTTP request.

## A real world example

A similar, real world example can be viewed in [gossboss](https://github.com/mdb/gossboss), a tool I recently wrote for collecting [Goss](https://github.com/aelsabbahy/goss) test results from multiple Goss servers.

`gossboss` can be run as a server or used as a CLI. For example, `gossboss healthzs` reports the Goss test results from each Goss server `--server` specified:

```bash
gossboss healthzs \
  --server "http://some-goss-server/healthz" \
  --server "http://another-goss-server/healthz"

✔ http://some-goss-server/healthz
✔ http://another-goss-server/healthz
```

`gossboss` fetches the test results concurrently, as its [`gossboss.Client#CollectHealthzs`](https://github.com/mdb/gossboss/blob/main/client.go#L53) method leverages a channel and goroutines:

```golang
func (c *Client) CollectHealthzs(urls []string) *Healthzs {
	hzs := &Healthzs{
		Summary: &Summary{
			Failed:  0,
			Errored: 0,
		},
	}
	ch := make(chan *Healthz)

	for _, url := range urls {
		go c.collectHealthz(url, ch)
	}

	// wait until all goss server test
	// results have been collected.
	for {
		hz := <-ch
		hzs.Healthzs = append(hzs.Healthzs, hz)

		if hz.Error == nil && hz.Result.Summary.Failed != 0 {
			hzs.Summary.Failed += hz.Result.Summary.Failed
		}

		if hz.Error != nil {
			hzs.Summary.Errored++
		}

		if len(hzs.Healthzs) == len(urls) {
			close(ch)
			break
		}
	}

	return hzs
}
```

For more insight on implementation details, check out [github.com/mdb/gossboss](https://github.com/mdb/gossboss). Do you have some ideas for how `gossboss` could be improved? Create a pull request.

## Pitfalls

### nil channels

Sending to a `nil` channel blocks forever and causes deadlock:

```golang
var ch chan string
ch<- "hello"
```

Similarly, receiving from a `nil` channel also blocks forever and causes
deadlock:

```golang
var ch chan string
<-ch
```

### Beware of leaked goroutines

A leaked goroutine is a goroutine that is started and expected to terminate, but
never does. As such, memory allocated for the Goroutine can't be released.

For example, the following `leaky()` function starts a goroutine that blocks receiving
from a channel. However, no value is ever sent to the channel, nor is the channel
ever closed:

```golang
func leaky() {
  ch := make(chan string)

  go func() {
    // <-ch blocks, waiting to receive a value from ch
    str := <-ch

    fmt.Println(str)
  }()
}
```

Alternatively, consider a more complex example. The following `leaky()` function
returns `"cancelled"` in 3 seconds, before the goroutine can send `"hello"` to
the unbuffered `ch` channel:

```golang
func leaky() string {
  // Create a channel
  ch := make(chan string)

  // Establish a context that times out within 3 seconds
  ctx, cancel := context.WithTimeout(context.Background(), 3 * time.Second)
  defer cancel()

  // Create a goroutine that sends "hello" to the ch channel after 10 seconds
  go func() {
    time.Sleep(10 * time.Second)
    ch <- "hello"
  }()

  select {
  case <-ctx.Done():
    return "cancelled"
  case result := <-ch:
    return result
  }
}
```

This is problematic, as sending on the `ch` channel blocks execution until
a receiver is available to receive the sent value. However, because `leaky()`
returned `"cancelled"` after 3 seconds -- before the goroutine wrote `"hello"`
to the `ch` channel -- there no longer is a `ch` receiver. This causes the
goroutine to block indefinitely waiting for receipt of `"hello"`.

However, making `ch` a _buffered_ channel with a capacity of `1` offers a simple fix:

```golang
ch := make(chan string, 1)
```

Through the use of a buffered channel, the goroutine can send `"hello"` on the
channel, despite that there is no receiver. This ensures the memory for that
goroutine will eventually be reclaimed.

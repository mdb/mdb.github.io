---
title: Profiling Go With pprof
date: 2020-10-07
tags:
- pprof
- golang
thumbnail:
teaser: My notes and personal cheat sheet for using pprof.
draft: true
---

These are my quick notes on profiling Go programs with [pprof](https://golang.org/pkg/runtime/pprof/). They're largely based on Julia Evans' excellent blog post [Profiling Go programs with pprof](https://jvns.ca/blog/2017/09/24/profiling-go-with-pprof/), which is worth a read.

## Basics

`pprof` collects CPU profiles, traces, and heap profiles for Go programs. It's a tool for visualizatio and analysis of this data.

There are generally two ways to use `pprof`:

1. Instrument code to generate a profile during development
2. Remotely analyze a profile via a web server

In my experience, typical usage generally involves remotely analyzing a profile via a webserver. It looks like:

1. Establish a web server for getting Go profiles: use the `net/http/pprof` package in your program
2. Save a profile: `curl localhost:$PORT/debug/pprof/$PROFILE_TYPE`
3. Analyze the profile: `go tool pprof`

`go tool pprof --help` will teach you a lot, too.

## Helpful reading

* [How to establish a pprof web server](https://golang.org/pkg/net/http/pprof/)
* [pprof developer documentation](https://github.com/google/pprof/blob/master/doc/pprof.md)
* [rakyll.org/archive/](https://rakyll.org/archive/)
* [Profiling Go](https://www.integralist.co.uk/posts/profiling-go/)

## What's a profile?

According to the [runtime/pproff docs](https://golang.org/pkg/runtime/pprof/):

> A Profile is a collection of stack traces showing the call sequences that led to instances of a particular event, such as allocation.

Furthermore:

> Packages can create and maintain their own profiles; the most common use is for tracking resources that must be explicitly closed, such as files or network connections.

Out of the box, a few profiles are pre-defined:

```text
goroutine    - stack traces of all current goroutines
heap         - a sampling of all heap allocations
threadcreate - stack traces that led to the creation of new OS threads
block        - stack traces that led to blocking on synchronization primitives
mutex        - stack traces of holders of contended mutexes
```

Each of these pre-defined profiles has its own endpoint in the default web server; `go tool pprof` can be used to analyze each. Again, these are profiles are collections of stacktraces, sometimes with some metadata attached:

* http://localhost:6060/debug/pprof/goroutine
* http://localhost:6060/debug/pprof/heap
* http://localhost:6060/debug/pprof/threadcreate
* http://localhost:6060/debug/pprof/block
* http://localhost:6060/debug/pprof/mutex

Additionally, the default web server offers a CPU profile and CPU trace endpoints:

* http://localhost:6060/debug/pprof/profile
* http://localhost:6060/debug/pprof/trace?seconds=5

Note: `/debug/pprof/trace?seconds=5` outputs a file that is _not_ a `pprof` profile but is a _trace_. It can be viewed via `go tool trace`.

## Julia Evans' technique for getting a heap profile with pprof

As [Julia writes](https://jvns.ca/blog/2017/09/24/profiling-go-with-pprof/), we can test drive debugging memory problems with `pprof` by writing a program that allocates a lot of memory and also establishes a `pprof` web server on port `6060`:

```golang
package main

import (
	"fmt"
	"log"
	"net/http"
	_ "net/http/pprof"
	"sync"
	"time"
)

func main() {
	// we need a web server to get the pprof web server
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()
	fmt.Println("hello world")
	var wg sync.WaitGroup
	wg.Add(1)
	go leakyFunction(wg)
	wg.Wait()
}

func leakyFunction(wg sync.WaitGroup) {
	defer wg.Done()
	s := make([]string, 3)
	for i := 0; i < 10000000; i++ {
		s = append(s, "magical pandas")
		if (i % 100000) == 0 {
			time.Sleep(500 * time.Millisecond)
		}
	}
}
```

Run the program: `go run main.go`

Now, enter an "interactive mode" of the heap profile for this program:

```bash
go tool pprof  http://localhost:6060/debug/pprof/heap
Fetching profile over HTTP from http://localhost:6060/debug/pprof/heap
Saved profile in /Users/mdb/pprof/pprof.alloc_objects.alloc_space.inuse_objects.inuse_space.002.pb.gz
Type: inuse_space
Time: Oct 7, 2020 at 7:31am (EDT)
Entering interactive mode (type "help" for commands, "o" for options)
```

In the interactive mode, `top` can be run, which tells us that `main.leadkyFunction` is using 7MB of memory:

```bash
(pprof) top
Showing nodes accounting for 7MB, 100% of 7MB total
      flat  flat%   sum%        cum   cum%
       7MB   100%   100%        7MB   100%  main.leakyFunction
```

Alternatively, a PNG profile can be generated, which visually represents the program's memory consumption:

```bash
go tool pprof -png http://localhost:6060/debug/pprof/heap > out.png
```

## alloc_space and inuse_space

Reading the output of `go tool pprof --help`, you'll note that there are options to sample allocation counts or in use memory:

```bash
-sample_index=alloc_space
-sample_index=inuse_space
```

According to Julia:

> If you’re concerned with the amount of memory being used, you probably want the inuse metrics, but if you’re worried about time spent in garbage collection, look at allocations!

## Understanding a pprof file

`.pb` files are protobuf files. If you're interested in viewing their contents, they can be viewed with `protoc` (you may need to do some internet searching for exact `protoc` installation instructions for your system).

mutex, block may show contention

## TODO: opening the handy web view

## Working with `trace`

Get a trace dump:

```text
wget http://localhost:8082/debug/pprof/trace\?seconds\=10 -O localdump
```

View it:

```bash
go tool trace localdump
2020/10/07 10:25:58 Parsing trace...
2020/10/07 10:25:58 Splitting trace...
2020/10/07 10:25:58 Opening browser. Trace viewer is listening on http://127.0.0.1:49813
```

in traceview
  goroutine "execution" in red shows time spent on CPU
  /networking - where we are waiting on network I/O (usually waiting on reads and writes; getaddrinfo would be a DNS lookup)
  /block shows mutex contention if  there's contention
  /syscall - waiting for OS to get back to us. writing to log file might show up here
  /sched - issues with runtime itself (numbers in MS)
  /mmu -

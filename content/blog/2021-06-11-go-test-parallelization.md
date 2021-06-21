---
title: Go Test Parallelization
date: 2021-06-11
tags:
- go
- test
- concurrency
thumbnail: peace_thumb.jpg
teaser: Leveraging concurrency in Go tests.
---

_A brief introduction to using Go's `testing` package's [`T.Parallel()`](https://golang.org/pkg/testing/#T.Parallel) to parallelize tests._

## Problem

Your Go project's tests are slow and run serially. Or perhaps they're not slow, but they run serially and could be faster.

## Solution

Consider running the test cases in parallel.

## Simple non-parallelized example

As a starting point, consider a simple non-parallelized test:

```golang
package main

import (
  "io/ioutil"
  "os"
  "testing"
  "time"
)

func TestSimple(t *testing.T) {
  testCases := []struct {
    name string
  }{{
    "1",
    }, {
    "2",
    }, {
    "3",
    }, {
    "4",
    }, {
    "5",
  }}

  t.Logf("Running %s tests...", len(testCases))

  for i, tc := range testCases {
    t.Run(tc.name, func(t *testing.T) {
      time.Sleep(3 * time.Second)

      expected := strconv.Itoa(i + 1)
      if expected != tc.name {
        t.Errorf("expected index %s to equal test %s", expected, tc.name)
      }
    })
  }
}
```

The code leverages a common [table driven testing](https://dave.cheney.net/2019/05/07/prefer-table-driven-tests) pattern: individual test case names are stored in a `testCases` anonymous struct literal and each test case is subject to an assertion. To futher illustrate the benefits of parallelization, the code also sleeps for three seconds during each test case iteration.

When run via `go test -v`, the following is logged:

```txt
$ go test -v
=== RUN   TestSimple
    paralling_test.go:24: Running 5 tests...
=== RUN   TestSimple/1
=== RUN   TestSimple/2
=== RUN   TestSimple/3
=== RUN   TestSimple/4
=== RUN   TestSimple/5
=== CONT  TestSimple
--- PASS: TestSimple (15.01s)
    --- PASS: TestSimple/1 (3.00s)
    --- PASS: TestSimple/2 (3.00s)
    --- PASS: TestSimple/3 (3.00s)
    --- PASS: TestSimple/4 (3.00s)
    --- PASS: TestSimple/5 (3.00s)
PASS
ok      github.com/mdb/paralleling      15.166s
```

Note that...

1. The test cases are executed and run to completion one at a time in the order in which they appear in `testCases`. This is evidenced by each `PASS: Testsimple/<test case index>` line.
2. The total test execution time is 15.166 seconds.

## A parallelized example

The following offers an example of how the test cases could be run in parallel; the new code is preceded by `// NOTE:` explanation comments:

```golang
package main

import (
  "testing"
  "time"
)

func TestSimple(t *testing.T) {
  testCases := []struct {
    name string
  }{{
    "1",
  }, {
    "2",
  }, {
    "3",
  }, {
    "4",
  }, {
    "5",
  }}

  t.Logf("Running %d tests...", len(testCases))

  for i, tc := range testCases {
    // NOTE:
    // Define a local 'tc' and 'i' variables inside the loop to keep
    // tc and i from from being re-assigned to the next test case with
    // each iteration.
    // More info: https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
    tc := tc
    i := i

    t.Run(tc.name, func(t *testing.T) {
      // NOTE:
      // Signal that this test is to be run in parallel with (and only with) other parallel tests.
      // https://golang.org/pkg/testing/#T.Parallel
      t.Parallel()

      time.Sleep(3 * time.Second)

      expected := strconv.Itoa(i + 1)
      if expected != tc.name {
        t.Errorf("expected index %s to equal test %s", expected, tc.name)
      }
    })
  }
}
```

Now, when run via `go test -v`, the following is logged:

```txt
go test -v
=== RUN   TestSimple
    paralling_test.go:24: Running 5 tests...
=== RUN   TestSimple/1
=== PAUSE TestSimple/1
=== RUN   TestSimple/2
=== PAUSE TestSimple/2
=== RUN   TestSimple/3
=== PAUSE TestSimple/3
=== RUN   TestSimple/4
=== PAUSE TestSimple/4
=== RUN   TestSimple/5
=== PAUSE TestSimple/5
=== CONT  TestSimple
=== CONT  TestSimple/1
=== CONT  TestSimple/3
=== CONT  TestSimple/2
=== CONT  TestSimple/4
=== CONT  TestSimple/5
--- PASS: TestSimple (0.00s)
    --- PASS: TestSimple/5 (3.00s)
    --- PASS: TestSimple/4 (3.00s)
    --- PASS: TestSimple/3 (3.00s)
    --- PASS: TestSimple/2 (3.00s)
    --- PASS: TestSimple/1 (3.00s)
PASS
ok      github.com/mdb/paralleling      3.319s
```

Note that...

1. The test cases no longer print `PASS: TestSimple/<test case index>` in the order in which they appear in `testCases`; the test cases now execute in parallel.
2. The total test execution time is 3.319 seconds, which is hardly longer than the 3 seconds each test case sleeps.

## Bonus

What about scenarios where common logic -- perhaps some cleanup -- must happen after all test cases are executed? How can such cleanup be guaranteed to happen _after_ the test cases, even when the tests panic?

At a glance, Go's [`defer`](https://tour.golang.org/flowcontrol/12) -- which registers a function to execute before its parent function returns -- _appears_ to be a good fit:

```golang
package main

import (
  "strconv"
  "testing"
  "time"
)

func TestSimple(t *testing.T) {
  testCases := []struct {
    name string
  }{{
    "1",
  }, {
    "2",
  }, {
    "3",
  }, {
    "4",
  }, {
    "5",
  }}

  t.Logf("Running %d tests...", len(testCases))

  // NOTE:
  // defer the execution until the parent function returns
  defer t.Logf("Finished running %d tests...", len(testCases))

  for i, tc := range testCases {
    tc := tc
    i := i

    t.Run(tc.name, func(t *testing.T) {
      t.Parallel()

      time.Sleep(3 * time.Second)

      expected := strconv.Itoa(i + 1)
      if expected != tc.name {
        t.Errorf("expected index %s to equal test %s", expected, tc.name)
      }
    })
  }
}
```

However, `defer` doesn't suffice, as the `defer`'d function executes immediately after `range`-ing over all the `testCases`, but before each `t.Run`'s function exits:

```txt
$ go test -v
=== RUN   TestSimple
paralling_test.go:24: Running 5 tests...
=== RUN   TestSimple/1
=== PAUSE TestSimple/1
=== RUN   TestSimple/2
=== PAUSE TestSimple/2
=== RUN   TestSimple/3
=== PAUSE TestSimple/3
=== RUN   TestSimple/4
=== PAUSE TestSimple/4
=== RUN   TestSimple/5
=== PAUSE TestSimple/5
=== CONT  TestSimple
paralling_test.go:43: Finished running 5 tests...
=== CONT  TestSimple/1
=== CONT  TestSimple/5
=== CONT  TestSimple/4
=== CONT  TestSimple/3
=== CONT  TestSimple/2
--- PASS: TestSimple (0.00s)
--- PASS: TestSimple/2 (3.00s)
--- PASS: TestSimple/1 (3.00s)
--- PASS: TestSimple/5 (3.00s)
--- PASS: TestSimple/3 (3.00s)
--- PASS: TestSimple/4 (3.00s)
PASS
ok      github.com/mdb/paralleling      3.171s
```

### Solution

Go's `testing` package ships with a [`Cleanup`](https://golang.org/pkg/testing/#B.Cleanup) function that "registers a function to be called when the test and all its subtests complete:"

```golang
package main

import (
  "strconv"
  "testing"
  "time"
)

func TestSimple(t *testing.T) {
  testCases := []struct {
    name string
  }{{
    "1",
  }, {
    "2",
  }, {
    "3",
  }, {
    "4",
  }, {
    "5",
  }}

  t.Logf("Running %d tests...", len(testCases))

  // NOTE:
  // Cleanup registers a function to be called when the test and all subtests complete.
  t.Cleanup(func() {
    t.Logf("Finished running %d tests...", len(testCases))
  })

  for i, tc := range testCases {
    tc := tc
    i := i

    t.Run(tc.name, func(t *testing.T) {
      t.Parallel()

      time.Sleep(3 * time.Second)

      expected := strconv.Itoa(i + 1)
      if expected != tc.name {
        t.Errorf("expected index %s to equal test %s", expected, tc.name)
      }
    })
  }
}
```

```txt
$ go test -v
=== RUN   TestSimple
    paralling_test.go:24: Running 5 tests...
=== RUN   TestSimple/1
=== PAUSE TestSimple/1
=== RUN   TestSimple/2
=== PAUSE TestSimple/2
=== RUN   TestSimple/3
=== PAUSE TestSimple/3
=== RUN   TestSimple/4
=== PAUSE TestSimple/4
=== RUN   TestSimple/5
=== PAUSE TestSimple/5
=== CONT  TestSimple/1
=== CONT  TestSimple/2
=== CONT  TestSimple/5
=== CONT  TestSimple/4
=== CONT  TestSimple/3
=== CONT  TestSimple
    paralling_test.go:27: Finished running 5 tests...
--- PASS: TestSimple (0.00s)
    --- PASS: TestSimple/3 (3.00s)
    --- PASS: TestSimple/4 (3.00s)
    --- PASS: TestSimple/1 (3.00s)
    --- PASS: TestSimple/5 (3.00s)
    --- PASS: TestSimple/2 (3.00s)
PASS
ok      github.com/mdb/paralleling      3.885s
```

As evidenced by the test output, `Finished running 5 tests...` no longer prints until after all parallelized test cases return.

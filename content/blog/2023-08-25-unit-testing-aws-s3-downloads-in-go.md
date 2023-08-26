---
title: "Unit Testing AWS S3 Downloads in Go"
date: 2023-08-25
tags:
- go
- s3
- aws
thumbnail: tigers_thumb.png
teaser: "How can a function wrapping the aws-sdk-go be unit tested using a local directory serving as a mock AWS S3 bucket?"
---

_An example of `github.com/aws/aws-sdk-go/awstesting/unit`'s use._

## Problem

How do you unit test a Go function that wraps `aws-sdk-go`'s
[s3manager#Downloader.Download](https://pkg.go.dev/github.com/aws/aws-sdk-go/service/s3/s3manager#Downloader.Download)
without issuing real HTTP requests to the AWS API (and without using an additional tool like [localstack](https://localstack.cloud/))?

## Solution

Make the implementation's `*s3manager.Downloader` configurable; in testing, use the
`github.com/aws/aws-sdk-go/awstesting/unit` package to create a custom
`*s3manager.Downloader` that uses a local `testdata` directory as a mock AWS S3 bucket.

## Example

Consider a contrived `s3object` package. The package provides an `S3Object`
type, which features a `Download` method that wraps [s3manager#Downloader.Download](https://pkg.go.dev/github.com/aws/aws-sdk-go/service/s3/s3manager#Downloader.Download)
and adds some extra logic.

By default, its `New` constructor configures a `*s3manager.Downloader` on the user's behalf. However, the constructor also
accepts a `WithDownloader` [functional option](https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis)
for optionally configuring the use of a non-default `*s3manager.Downloader`.

```go
package s3object

import (
  "net/url"
  "os"
  "strings"

  "github.com/aws/aws-sdk-go/aws"
  "github.com/aws/aws-sdk-go/aws/session"
  "github.com/aws/aws-sdk-go/service/s3"
  "github.com/aws/aws-sdk-go/service/s3/s3manager"
)

// S3Object is an S3 object.
type S3Object struct {
  downloader *s3manager.Downloader
}

// S3ObjectOption is a functional option used to configure a new *S3Object.
type S3ObjectOption = func(s3o *S3Object)

// WithDownloader is a DownloaderOption for configuring the use of a specific
// *s3manager.Downloader.
func WithDownloader(d *s3manager.Downloader) S3ObjectOption {
  return func(s3o *S3Object) {
    s3o.downloader = d
  }
}

// New returns a new *S3Object using the *url.URL it's passed.
func New(u *url.URL, opts ...S3ObjectOption) *S3Object {
  sess := session.Must(session.NewSession(&aws.Config{
    Region: aws.String("us-east-1"),
  }))
  downloader := s3manager.NewDownloader(sess)

  s3o := &S3Object{
    downloader: downloader,
  }

  for _, opt := range opts {
    opt(s3o)
  }

  return s3o
}

// Download downloads the S3 object from the URL it's passed.
// It saves the object to a local file named after the last part of the URL's path.
func (s3o *S3Object) Download(u *url.URL) error {
  fileName := u.Path[strings.LastIndex(u.Path, "/")+1:]
  file, err := os.Create(fileName)
  defer file.Close()
  if err != nil {
    return err
  }

  _, err = s3o.downloader.Download(file, &s3.GetObjectInput{
    Bucket: aws.String(u.Host),
    Key:    aws.String(u.Path),
  })

  return err
}
```

Using the `github.com/aws/aws-sdk-go/awstesting/unit` package, a test
`*s3manager.Downloader` can be created, provided below via the `testDownloader()`
function. In this case, the `*s3manager.Downloader` provided by `testDownloader()`
treats a local `testdata` directory as a mock S3 bucket.

The `s3object.New` constructor's support for a `WithDownloader` functional
option enables the `s3object.Object` under test to use the
`*s3manager.Downloader` provided by `testDownloader()`.

```golang
package s3object_test

import (
  "bytes"
  "fmt"
  "io/ioutil"
  "net/http"
  "net/url"
  "os"
  "strings"
  "sync"
  "testing"

  "github.com/aws/aws-sdk-go/aws/request"
  "github.com/aws/aws-sdk-go/awstesting/unit"
  "github.com/aws/aws-sdk-go/service/s3"
  "github.com/aws/aws-sdk-go/service/s3/s3manager"
  "github.com/mdb/s3object"
)

func testDownloader() *s3manager.Downloader {
  var locker sync.Mutex
  svc := s3.New(unit.Session)
  svc.Handlers.Send.Clear()
  svc.Handlers.Send.PushBack(func(r *request.Request) {
    locker.Lock()
    defer locker.Unlock()

    r.HTTPResponse = &http.Response{
      Header: http.Header{},
    }

    f, err := os.ReadFile(fmt.Sprintf("testdata%s", r.HTTPRequest.URL.Path))
    switch err {
    case nil:
      // If there's no error reading the file, return a 200 HTTP response with
      // the file contents as the response body.
      r.HTTPResponse.StatusCode = http.StatusOK
      r.HTTPResponse.Body = ioutil.NopCloser(bytes.NewReader(f))
    default:
      // Otherwise, return a 500 HTTP response with the error as the body.
      r.HTTPResponse.StatusCode = http.StatusInternalServerError
      r.HTTPResponse.Body = ioutil.NopCloser(strings.NewReader(err.Error()))

      // But, if the error occurs because the file doesn't exist, return a 404
      // HTTP response.
      if os.IsNotExist(err) {
        r.HTTPResponse.StatusCode = http.StatusNotFound
      }
    }

    r.HTTPResponse.Header.Set("Content-Length", "1")
  })

  return s3manager.NewDownloaderWithClient(svc, func(d *s3manager.Downloader) {
    d.Concurrency = 1
    d.PartSize = 1
  })
}

func TestDownload(t *testing.T) {
  tests := []struct {
    desc        string
    path        string
    expectedErr bool
  }{{
    desc:        "does not exist",
    path:        "testdata/does-not-exist/bim.txt",
    expectedErr: true,
  }, {
    desc:        "exists",
    path:        "testdata/foo/bar.txt",
    expectedErr: false,
  }}

  for _, test := range tests {
    t.Run(test.desc, func(t *testing.T) {
      u, err := url.Parse(fmt.Sprintf("s3://%s", test.path))
      if err != nil {
        t.Error(err)
      }

      newFileName := u.Path[strings.LastIndex(u.Path, "/")+1:]
      t.Cleanup(func() { os.Remove(newFileName) })

      s3o := s3object.New(u, s3object.WithDownloader(testDownloader()))

      err = s3o.Download(u)
      if err != nil && !test.expectedErr {
        t.Error(err)
      }

      if err == nil && test.expectedErr {
        t.Error("expected error")
      }

      if test.expectedErr {
        return
      }

      originalFileContent, err := ioutil.ReadFile(test.path)
      if err != nil {
        t.Fatalf("unable to read file: %v", err)
      }

      newFileContent, err := ioutil.ReadFile(newFileName)
      if err != nil {
        t.Fatalf("unable to read file: %v", err)
      }

      if string(originalFileContent) != string(newFileContent) {
        t.Errorf("expected %s contents to equal %s", newFileName, test.path)
      }
    })
  }
}
```

The project directory looks like the following; note the `testdata` directory,
which serves as the fake S3 bucket used in tests:

```
├── go.mod
├── go.sum
├── s3object.go
├── s3object_test.go
└── testdata
    └── foo
        └── bar.txt

3 directories, 5 files
```

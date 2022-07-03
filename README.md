[![CI](https://github.com/mdb/mdb.github.io/actions/workflows/ci.yml/badge.svg)](https://github.com/mdb/mdb.github.io/actions/workflows/ci.yml) [![CD](https://github.com/mdb/mdb.github.io/actions/workflows/cd.yml/badge.svg)](https://github.com/mdb/mdb.github.io/actions/workflows/cd.yml)

# [mikeball.info](http://mikeball.info)

Personal website, over a decade of blog posts and notes about software engineering, some archived projects, etc.

Built using [hugo](https://gohugo.io).

## Development

Run a development server on `localhost:1313`:

```
make serve
```

## Build

Compile site to a `public` directory:

```
make
```

## Deploy

The `main` branch is continuously deployed via a [CD GitHub action workflow](https://github.com/mdb/mikeball.info/actions?query=workflow%3ACD).

Alternatively:

```
make deploy
```

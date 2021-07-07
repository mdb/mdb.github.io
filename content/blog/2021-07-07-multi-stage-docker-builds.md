---
title: Multi-stage Docker Builds
date: 2021-07-07
tags:
- docker
- containers
- CI/CD
thumbnail: brooklyn_sky_thumb.jpg
teaser: An introduction to leveraging multi-stage container image builds.
---

_An introduction to leveraging multi-stage container image builds._

## Problem

Your application is deployed via a minimal [OCI](https://opencontainers.org/) image, such as one produced by a [Docker build](https://docs.docker.com/engine/reference/commandline/build/). However, its build and test pipeline consists of many stages, each of which utilizes disparate technologies, system dependencies, and testing techniques. Consistently managing the build pipeline -- and its dependencies -- across local development environments and CI/CD systems is complicated. Perhaps its configuration and dependency management is spread across [package.json](https://docs.npmjs.com/cli/v7/configuring-npm/package-json#scripts) scripts, [Make](https://stackoverflow.com/questions/2270643/what-is-a-make-target/2270701) targets, [Github Actions](https://github.com/features/actions) YML, a [homebrew](https://brew.sh/) `Brewfile`, a `Dockerfile`, and/or Linux package managers with no consistent entrypoint.

## A potential solution

Consider leveraging [multi-stage `docker` image builds](https://docs.docker.com/develop/develop-images/multistage-build/) and leaning into Docker (or another [OCI image technology](https://opencontainers.org/)) as the standard entrypoint and single dependency used to consistently build and test your software across all environments.

## A basic example

Consider a simple, contrived example in which a `hello` application is deployed via a container image.

When built and run, the `hello` application prints `hello`:

```bash
docker build --tag hello .
[+] Building 0.9s (7/7) FINISHED
...
```

```bash
docker run hello
hello
```

### Before

Prior to leveraging multi-stage Docker builds, `hello` is built via a minimal `Dockerfile`:

```Dockerfile
FROM alpine

COPY hello.sh /hello.sh

ENTRYPOINT ["/hello.sh"]
```

However, before building the `hello` image, the CI/CD and local build processes might subject `hello.sh` to [shellcheck](https://github.com/koalaman/shellcheck) analysis, ensuring that the script conforms to common shell script conventions and contains no syntax errors.

In local development, the installation and invocation of `shellcheck` might be managed via a `Makefile`. In CI/CD, `shellcheck` might be invoked via the [action-shellcheck](https://github.com/marketplace/actions/shellcheck) GitHub Action prior to a [GitHub Actions-based Docker build](https://github.com/marketplace/actions/build-and-push-docker-images).

### After

Rather than manage multiple `shellcheck` installation and invocation techniques, perhaps the build process could be streamlined via a multi-stage image build in which `shellcheck` is invoked directly from within the `docker build`:

```Dockerfile
FROM koalaman/shellcheck-alpine AS shellchecker

COPY hello.sh /hello.sh

RUN shellcheck /*.sh

FROM alpine

COPY --from=shellchecker /hello.sh /hello.sh

ENTRYPOINT ["/hello.sh"]
```

Now...

* `docker` becomes the sole build-and-run-time dependency across all environments
* `shellcheck` is invoked in a standard way across both local development and CI/CD environments; the disparate `Makefile`-based and GitHub Actions-based `shellcheck` invocation code can be deleted

Also note that the final `hello` image remains sufficiently minimal; `shellcheck` is only installed during the `shellchecker` stage and is not present in the final `hello` image.

## Summary

While the `hello` example is fairly simplistic and contrived, multi-stage Docker builds could be far more sophisticated, even executing unit, functional, and and even integration tests from within the Docker build.

Aggressively utilizing multi-stage Docker builds to streamline build and test processes may not be appropriate in all contexts. However, the technique's worth considering and can simplify many workflows.

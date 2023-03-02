---
title: Notes on Implementing Backstage
date: 2023-02-08
tags:
- backstage
- platform engineering
- typescript
thumbnail:
teaser:
---

_Spotify's [Backstage](https://backstage.io/) project has been enjoying recent critical acclaim. These are my notes on my own experience implementing Backstage for a large organization._

## What is Backstage?

Backstage bills itself as an "open platform for building developer portals." As its backbone, Backstage offers a service catalog, but also a rich [ecosystem of plugins]() for integrating other, third party tools: CI/CD pipelines, observability dashboards, documentation, cloud providers, infrastructure-as-code resources, incident management, project management, etc. It also enables push button automation for generating software projects from "golden path" templates. Beyond the open source marketplace of community-maintained plugins, Backstage can be extended via proprietary, in-house plugins. Essentially, Backstage aspires to be an [internal developer platform](https://internaldeveloperplatform.org/) that ties together an organization's disparate tooling as an integrated user experience.

Backstage was a originally developed and open sourced by Spotify. As of the time of writing, it's a Cloud Native Computing Foundation incubating project.

## Adoption

Using open source projects like [Grafana](https://grafana.com/) as a frame of reference, prospective Backstage adopters may expect to deploy a binary or container image released by the upstream [github.com/backstage/backstage](https://github.com/backstage/backstage) project. However, that's not exactly how things work with Backstage. By contrast, [github.com/backstage/backstage](https://github.com/backstage/backstage) is a monorepo homing a collection of [lerna](https://lerna.js.org/) TypeScript packages. Adopters use the [backstage CLI](TODO) to instantiate their own codebase, which is itself a monorepo composed of TypeScript packages built on top of the upstream open source packages maintained within the github.com/backstage/backstage monorepo (and perhaps supplemented by community-maintained Backstage plugins, such as those homed in [github.com/RoadieHQ/roadie-backstage-plugins](https://github.com/RoadieHQ/roadie-backstage-plugins). In this sense, adopters are _implementing_ their own, customized instance of Backstage. So, writing some TypeScript and maintaining your own Backstage development process (and associated CI/CD pipeline) is likely inevitable.

## Warnings

Beyond being prepared to write a lil' TypeScript and do a bit of `yarn`-ing, prospective adopters may also wanna note a few other potential challenges...

* Because adopters cherry pick the plugins they'd like to use in their own Backstage implementation -- and because the upstream packages may experience rapid development -- dependency compatibility and upgrades can get thorny. Perhaps my own `yarn`/lerna naivete is to blame, but I've often struggled in finding the magic combination of package versions required to enable -- or upgrade -- a plugin without breaking other, peripheral stuff.
* In my experience, Backstage documentation can be great, but it can also be stale or altogether nonexistent, depending on the topic. Maybe be prepared to read lotsa source code to answer undocumented questions.
* Many plugins require the Backstage backend to be configured as a reverse proxy fronting an upstream third party HTTP API, thus enabling the plugin to issue CORS requests to the Backstage backend reverse proxy endpoint to access associated data. For example, the PagerDuty plugin requires the following proxy configuration be set in the `app-config.yaml` file configuring Backstage:

    ```yaml
    proxy:
      '/pagerduty':
        target: https://api.pagerduty.com
        headers:
          Authorization: Token token=${PAGERDUTY_TOKEN}
    ```

    However, be warned: in many cases, this can inadvertently expose the underlying third party API as an unprotected Backstage endpoint, in effect granting any actor with Backstage access elevated privileges to the proxied API using the configured credentials. Depending on context, restricting the proxied endpoint to only serve `GET` requests -- and therefore deny `PUT`s, `POST`s, and `DELETE`s associated with non-read-only requests -- may offer a quick/dirty means of making the proxied endpoint "read only:"

    ```yaml
    proxy:
      '/pagerduty':
        target: https://api.pagerduty.com
        headers:
          Authorization: Token token=${PAGERDUTY_TOKEN}
        # prohibit the `/pagerduty` proxy endpoint from servicing non-GET requests
        allowedMethods: ['GET']
    ```

    (Using API credentials adhering to the principle of least privilege is a good idea too.)
* TODO: catalog metadata (individual repos vs central location)

## Good stuff

In my experience, Backstage can be practically helpful

Story books is good
Contribution experience is great
Active Discord community
Generally, the UX provided by Backstage is well-received and folks are energeized by Backstage.
Provides a good vehicle towards DevOps-oriented collaboration and shared vision
Helpful framework through which to implement ad hoc UIs via plugins

Internal success stories
change-events plugin
AWS plugin inventorying accounts and EKS clusters
Observability plugin
  dynamically surfacing links to logs, relevant Grafana dashboards
  dynamically surface details on entity version(s) deployed across each environment, market, and cluster

Notes on how we've done things
You'll likely need to implement CI/CD automation for packaging and deploying your own Backstage "implementation"
We found it easier and more sustainable to centralize and automate the catalog descriptor generation via a GHA cron job than to expect each repo to maintain their own
  tradeoff: that automation keys off of context clues, such as CICD pipeline YAML, etc. that invites complexity and could itself go stale

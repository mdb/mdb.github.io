---
title: Notes on Implementing Backstage
date: 2023-03-03
tags:
- backstage
- platform engineering
- typescript
thumbnail: backstage_thumb.png
teaser: Some notes on my experience implementing Backstage for a large engineering organization.
---

_Spotify's [Backstage](https://backstage.io/) project has been enjoying some recent acclaim. A colleague asked about my experience implementing Backstage for a large organization. These are my quick, dirty, and not-quite-comprehensive-but-hopefully-still-useful-ish notes._

## What is Backstage?

Backstage bills itself as an "open platform for building developer portals." As its backbone, Backstage offers a service catalog, but also a healthy [ecosystem of plugins](https://backstage.io/plugins) for integrating other, third party tools: stuff like CI/CD pipelines, observability dashboards, documentation, cloud providers, infrastructure-as-code resources, incident management, project management, etc. It also enables push button automation for generating software projects from "golden path" templates. Beyond the open source marketplace of community plugins, Backstage can be extended via in-house plugins. Essentially, Backstage aspires to enable the creation of an [internal developer platform](https://internaldeveloperplatform.org/) that ties together an organization's software and disparate tooling as a cohesive experience.

Backstage was originally developed and open sourced by Spotify. As of the time of writing, it's a Cloud Native Computing Foundation incubating project and evidently received lotsa buzz at this year's KubeCon.

[backstag.io](https://backstage.io/) offers a more comprehensive overview, which is worth reading too.

## Adoption kinda means _implementation_

Prospective Backstage adopters may expect to deploy a binary or container image released by the upstream [github.com/backstage/backstage](https://github.com/backstage/backstage) project (like how [Grafana](https://github.com/grafana/grafana) publishes [pre-compiled release binaries](https://grafana.com/grafana/download/9.4.3?edition=oss), for example). However, that's not exactly how things work with Backstage. By contrast, [github.com/backstage/backstage](https://github.com/backstage/backstage) is a monorepo homing a collection of [lerna](https://lerna.js.org/) TypeScript packages. Adopters run `npx @backstage/create-app@latest` to instantiate their own Backstage codebase, which is itself a monorepo composed of TypeScript packages built on top of the packages maintained within the `github.com/backstage/backstage` monorepo (and perhaps further supplemented by community-maintained Backstage plugins maintained elsewhere, such as those homed in [github.com/RoadieHQ/roadie-backstage-plugins](https://github.com/RoadieHQ/roadie-backstage-plugins)). In this sense, adopters are _implementing_ their own, customized instance of Backstage (this language -- "_implementing_ Backstage" -- is commonly used throughout the Backstage community in reference to adopters running their own Backstage instances).

## Some other callouts

With all that as context, prospective adopters may wanna note a few callouts and potential challenges...

Because adoption requires _implementation_ -- and not just operation -- writing some TypeScript and maintaining your own Backstage development process (and CI/CD pipeline) is likely inevitable. Relative familiarity with [yarn](https://yarnpkg.com/) and [lerna](https://lerna.js.org/) is kinda necessary too.

Because adopters cherry pick the plugins they'd like to use in their own Backstage implementation -- and because the upstream packages may experience rapid development -- dependency compatibility and upgrades can get thorny. Perhaps my own `yarn`/lerna naivete is to blame, but I've often struggled in finding the magic combination of package versions required to enable -- or upgrade -- a plugin without breaking other, peripheral stuff. [Backstage upgrade helper](https://backstage.github.io/upgrade-helper/) is a thing, but I've had mixed results using it (again, maybe implicating my own naivete?).

In my experience, Backstage [documentation](https://backstage.io/docs/overview/what-is-backstage) can be good, but it can also be stale or altogether nonexistent, depending on the topic. Answering undocumented questions may require reading lotsa source code.

Many plugins require the Backstage backend to be configured as a reverse proxy fronting an upstream third party HTTP API, thus enabling the plugin to issue CORS requests to the Backstage backend proxy endpoint to access associated data. For example, the PagerDuty plugin requires the following proxy configuration be set in the `app-config.yaml` file configuring Backstage:

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

According to [the docs](https://backstage.io/docs/permissions/overview), "Backstage endpoints are not protected, and all actions are available to anyone." So, to some extent -- and depending on how you've implemented Backstage -- the above-described problem of elevated privileges may pertain to other unprotected endpoints as well. The [permissions system](https://backstage.io/docs/permissions/overview) seeks to mitigate this, but is relatively new and requires unpacking some documentation, squinting at examples, and _maaaaybe_ even rolling your own cookie-validation middleware in some contexts. Plus, many plugins don't yet utilize the permissions system (disclaimer: I myself don't fully understand the permissions system so fact check me on all this).

The Backstage service catalog requires the maintenance of [entity descriptor YAML](https://backstage.io/docs/features/software-catalog/descriptor-format), generally homed in one or more git repositories. Be prepared to noodle on whether you'd prefer this YAML be manually maintained or generated via automation, and whether you'd prefer it live in a central location, or whether each descriptor lives in its corresponding codebase. This'll likely be informed by questions like: what sortsa entities are being cataloged? Are the entities homed in discrete git repositories or within a shared monorepo? How can you ensure the descriptors' accuracy and prevent stale descriptors?

As a frame of reference, I've had relative success automating the generation of entity descriptors via a GitHub Actions workflow that periodically scrapes metadata from an organization's individual git repositories, then saves the generated descriptors to a central `backstage-catalog` git repository. But again, YMMV and the preferred technique largely hinges on contextual details such as how you've organized source code repositories, and how those repositories relate to service catalog entities.

## The good stuff

None of the above-listed callouts are necessarily deal breakers -- just some stuff to be aware of (and Backstage is being continuously improved so it's also worth fact checking me on the continued relevance of all this). Beyond the challenges, though, Backstage offers some clear value, too, at least by my assessment...

In my experience, the UX provided by Backstage is well-received and an internal Backstage instance is genuinely viewed as helpful. I'm often skeptical of excess tooling ([YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it)), but I do believe I've seen Backstage prove its value, namely in creating a cohesive developer platform experience from an otherwise disjointed soup of software, tools, teams, processes, etc. Plus, there's a chance its [plugins](https://backstage.io/plugins) can fast track your organization in enabling common capabilities you're already planning to provide (I'm thinking of "golden path" project generation via the software templates plugin in particular). I've also seen Backstage facilitate DevOps-oriented collaboration and shared understanding, which I think deserves honorable mention as valuable in/of itself.

Beyond its existing plugins, Backstage offers a sensible, [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)-ish home for internal web applications that might otherwise sprawl across multiple codebases, URLs, frameworks, CLIs, APIs, etc. Rather than built as one-off web UIs and implementations, internal tools can be developed as Backstage plugins standing on the shoulders of the Backstage backend system, framework, and existing React components. Need to build a UI indexing platform change events? Or an inventory of AWS accounts? Or a landing page visualizing Kubernetes cluster deployments around the world? Implementing such things as Backstage plugins -- rather than one-off applications -- may expedite productivity (and make more sense, UX-wise).

On that note, if you're building plugins, Backstage's [Storybook](https://backstage.io/storybook/) is super useful and contains lotsa helpful UI patterns and examples.

Also, the upstream open source community and maintainers are engaged and welcoming. I've had a positive experience contributing pull requests to [github.com/backstage/backstage](https://github.com/backstage/backstage). There's lotsa good [community channels](https://backstage.io/docs/overview/support/) for learning and staying abreast of news too.

## Is adopting Backstage worth it?

There's no easy way to assess whether adopting Backstage will prove worthwhile to your organization. Inevitably, adoption requires some overhead and therefore some risk to other goals. Nonetheless, my own experience is largely positive; I'm generally bullish on Backstage's potential, especially in organizational contexts where its core features (service catalog, software templating, etc.) are already prioritized as necessary.

Have I misrepresented anything? Do you see typos or room for improvement? [Submit a PR](https://github.com/mdb/mdb.github.io).

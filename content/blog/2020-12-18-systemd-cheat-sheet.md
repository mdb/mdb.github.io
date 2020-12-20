---
title: A systemd Cheat Sheet
date: 2020-12-18
tags:
- operations
- linux
- systemd
thumbnail: crowded_park_thumb.png
teaser: A personal systemd overview and cheat sheet
---

_Generally, `systemd` is the standard init system across Linux
distributions. `systemctl` is its central CLI management tool.
This is a brief overview and cheat sheet._

## Background

* `systemd` is responsible for initializing and managing components, services,
and daemons that must be started after the kernel is booted. Such components
are often referred to as "userland" components.
* resources managed by `systemd` are called _units_; these are defined in unit
files
* service management unit files are suffixed with a `.service` (though there are
other types of units too, such as `.socket`, `.device`, `.mount`, etc. This overview
focuses on `.service` units, though)

## Starting/Stopping services

* `systemctl start something.service` - start a service
* `systemctl stop something.service` - stop a service
* `systemctl restart something.service` - restart a service

## Reloading configuration

* `systemctl reload something.service` - reload a service's configuration
without restarting the service, assuming the service is capable of this
* `systemctl reload-or-restart something.service` - reload a service's
configuration in place, if the service is capable of doing so (otherwise, restart the
service to pick up the new configuration)
* `systemctl daemon-reload` reloads the entire `systemd` process

## Enabling services

* `systemctl enable something.service` - _enable_ a service, causing the service
to be automatically started at boot (Note, however, this does not start the
service in the current session; that still requires a `start`)
* `systemctl disable something.service` - disable a service from starting at boot

## Querying status

* `systemctl status something.service` - outputs the service's state, the cgroup hierarchy, and the first serveral log lines
* `systemctl is-active something.service` - reports if a service is running
* `systemctl is-enabled something.service` - reports if a service is enabled
* `systemctl is-failed something.service` - reports if a service is in a failed state

## Learning more about a system's units

* `systemctl list-units` - lists active units
* `systemctl list-units --all --state=active` - lists all active units

(Other options exist too.)

## Learning more about a unit's details

* `systemctl cat something.service` - output the service's unit files
* `systemctl list-dependencies something.service` - outputs a hierarchy of the service's dependencies (i.e. other services required by it)
* `systemctl show something.service` - outputs the properties associated with a service

## Unit files

* unit files usually live in `/lib/systemd/system`
* `.conf` files in `.d` directories like `/etc/systemd/system/something.service.d` containing "snippets" are merged on load with a unit definition to override or extend the unit definition with the "snippet"
* `.service` unit files in `/etc/systemd/system` completely override the unit definition usually found in `/lib/systemd/system`
* [Understanding systemd Units and Unit Files](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files) offers a detailed overview of unit file "anatomy"

A very basic example:

```text
[Unit]
Description=something

[Service]
ExecStart=/bin/bash -c "something"

[Install]
WantedBy=multi-user.target
```

## journalctl

`journalctl` is the CLI tool for `journal`, which is responsible for collecting and managing `systemd` logs.

A few examples of working with `journalctl`:

* `journalctl` - outputs the `systemd` logs
* `journalctl -u something -f` - outputs the logs for a service (Note that `journalctl` is a separate command and process for managing)
* `journalctl --since yesterday` or `journalctl --since 09:00 --until "1 hour ago"` can be used to filter logs to a specific window of time
* `journalctl -p err -b` - shows only log entries logged at the error level or above
* `journalctl -o json-pretty` - shows logs in formatted JSON (other output options exist, too)

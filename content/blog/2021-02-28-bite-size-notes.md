---
title: Bit Size Networking Notes
date: 2021-02-28
tags:
- software development
- professional development
thumbnail: summer_mountains_thumb.png
teaser: My notes on Julia Evans' "Bite Size Networking" zine, plus some of my own thoughts.
draft: true
---

# Bit Size Networking

## dig

* `dig` is a tool for performing and learning more about DNS queries. It's useful when you need to learn more about how a DNS name -- such as `google.com` -- resolves (or perhaps why it doesn't resolve).
* `dig @8.8.8.8 google.com` explicitly queries the `@`-specified DNS server (`8.8.8.8` is Google's DNS server).
* `dig +trace google.com` traces how the DNS name gets resolved, starting at the root nameservers. This is helpful if you've just updated a record and should show the new record.
* `dig -x 172.217.12.206` makes a reverse DNS query to find a record associated with an IP (but assumes a [PTR](https://en.wikipedia.org/wiki/List_of_DNS_record_types#PTR) record exists.)
* `dig +short google.com` prints less output

## ping

* `ping google.com` checks if you can reach `google.com` by sending an ICMP packet and wating for a reply. It also reports latency.
* note that some hosts never respond to ICMP packets; this doesn't necessarily mean the host is down

## traceroute

* useful in understanding the network path between a source and destination
* `traceroute google.com` reports the network path a packet takes to reach a target, in this case `google.com`
* `tcptraceroute google.com 443` operates over TCP and allows you to specify a port in addition to a host. This is helpful if you need to check connectivity to a specific port and suspect an intermediary firewall is blocking such connectivity.
* `mtr` is similar to `traceroute`, but refreshes its output in real time.

## netcat

* `netcat` is used to create TCP (or UDP) connections. This is useful in determining whether a source can connect to a destination host over a specified port, as is common when debugging connectivity issues or firewalls.
* `nc -vz google.com 443` ascertains whether you can TCP connect to `google.com` over port `443`.

## nmap

* allows you to explore a network and discover information such as open ports
* `nmap -v -A google.com` performs an _aggressive_ port scan of `google.com`
* `nmap -F` scans fewer ports, focusing on the most common ones
* `nmap -sn 192.168.1.0/24` finds what hosts are up in your local home network
* `nmap --help` or `man nmap` explains its many more options

## tcpdump

* `tcpdump` is useful for viewing network packets sent and received
* `sudo tcpdump -n dst host google.com -w file.pcap` records `google.com`-destined packets and writes the results to a `file.pcap`, which can be analyzed via tools like `tcpdump` itself, wireshark, or `tshark`.
* `man tcpdump` explains much more. Suffice to say, it's a complicated tool.

## tshark

* `tshark` is the command line version of Wireshark and is a packet analysis tool. It's similar to `tcpdump`, but has more features.
* `tshark -Y 'http.request.method == "GET"'` filters the captured packets to just those associated with HTTP `GET` requests
* `-T` can be used to specify a format, including JSON
* `-e` can be used to specify which fields to output. For example: `tshark -T fields -e http.request.method -e http.request.uri -e ip.dst`

## ngrep

* `ngrep` is similar to `tcpdump`, but perhaps a bit more beginner-friendly
* `sudo ngrep GET` captures every HTTP `GET` originating from your machine

## lsof

* `lsof` is handy on Mac OS for finding what process is using what port
* `lsof -i tcp:1313` reports the process (and its PID) listening on port `1313`, for example
* `ss` is similarly handy on Linux. For example, `ss -tunpl` shows all running servers.

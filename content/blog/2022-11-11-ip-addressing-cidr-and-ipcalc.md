---
title: IP addressing, Networks, Subnets, and CIDR
date: 2022-11-11
tags:
- networking
- ip
- ipcalc
- infrastructure engineering
thumbnail: wudder_thumb.png
teaser: A brief overview of IP addressing, with a focus on CIDR notation and an introduction to ipcalc.
---

_Working with IP addresses, networks, subnets, and [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) notation can be confusing. Intended as a resource for junior engineers -- as well as my own personal notes -- the following offers some overview, history, and an introduction to `ipcalc`._

Big disclaimer: I'm not a network engineer :)

## IP addresses

An _internet protocal address_ is a numerical label connected to a computer network that uses the [internet protocol](https://en.wikipedia.org/wiki/Internet_Protocol) for communication. IP addresses serve two main functions:

1. network interface identification
2. location addressing

IP address space is managed globally by the Internet Assigned Numbers Authority (IANA), and by five regional internet registries (RIRs), each responsible in their designated territory for address assignment to local registries, such as Internet service providers (ISPs), and other entities.

## IP address routing

IP addresses are grouped into four classes of operational characteristics:

1. unicast
    * refers to a single sender or a single receiver
    * most common usage
    * available to both IPv4 and IPv6
1. broadcast
    * address data to all possible destinations on a network in one transmission operation
    * available in IPv4; IPv6 does not implement this and instead replaces it with multicast to the special all-nodes multicast address
1. multicast
    * associated with a group of interested receivers
    * sender sends a single datagram from its unicast address to the multicast group address; intermediary routers make copies and send them to all interested receivers based on multicast group membership
    * IPv4 uses `224.0.0.0` - `239.255.255.255` (the former class D addresses) as multicast addresses
    * IPv6 uses the address block with the prefix `ff00::/8` for multicast
1. anycast
    * one-to-many routing (similar to broadcast and multicast), though the data stream is only transmitted to the receiver determined by the router to be closest
    * useful in global load balancing and DNS

## Classless Inter-Domain Routing (CIDR)

CIDR defines how many addresses are in a network block; it's essentially a method for allocating IP addresses and for IP routing. It was created by the _Internet Engineering Task Force_ in 1993 to replace the internet's previous _classful_ addressing architecture and introduced the _CIDR notation_ method for representing IP addresses.

By comparison, _classful_ networking was the old school pre-CIDR model that used to align with how IANA doled out public IP address space: companies like Comcast got a Class A, schools and government agencies got a B, and small ISPs or SMBs got a C (or multiple Cs), for example. They correspond to the CIDR lengths `/8`, `/16`, `/24`. Additionally, class D represents the multicast class, and class E is experimental and reserved for future use (though may never be used, given the advent of IPv6). CIDR is the newer means of allocating smaller chunks of space (or chunks of IP address space that don't align on class A/B/C boundaries, anyways).


CIDR notation represents an IP address or routing prefix, and denotes the routing prefix's size by suffixing the address with the number of bits. For example: `192.0.2.0/24` (equivalent to the historically used subnet mask `255.255.255.0`) for IPv4, and `2001:db8::/32` for IPv6.

## Let's focus on IPv4

IPv4 addresses may be in any notation expressing a 32-bit integer value. However, for human convenience, IP4 addresses are often represented in dot-decimal notation, which consists of four octets of the address expressed individually in decimal and separated by periods. Each octet consists of 8 bits giving a value between 0 and 255. What we talk about when we refer to a "dotted-decimal quad" IPv4 address is really a 32-bit integer to the computer. The number after the `/` (i.e. `192.168.1.0/24`) denotes the number of bits out of 32 used to describe the network range. In other words, an IP address followed by a `/` and a number indicates a block of addresses.

## Private networks

The [RFC 1918](https://datatracker.ietf.org/doc/html/rfc1918) "reserved private" ranges are called "class A, B, C" vestigally because they happen to be sized like the old school, pre-CIDR classfull A, B, and C ranges allocated by IANA.

* Class A - `10.0.0.0/8`
* Class B - `172.16.0.0/12`
* Class C - `192.168.0.0/16`

Admins can use RFC 1918 addresses however they like. However, they must agree within a network's boundaries and packets with those RFC 1918 source or destination addresses are not directly sendable  over the internet (at least not without encapsulation, such as tunneling/VPN).

By convention, it's common for network admins to use the `10.0.0.0/8` class A block for corporate internal WAN, becuase its large size allows for slicing/dicing and delegation to LAN admins.

Source network address translation (SNAT) and destination network address translation (DNAT) are the common means of translating RFC 1918 addresses into something that can travel over the internet. SNAT translates a source IP address when connecting from a private IP address to a public IP address, and is the most common form of NAT used when a private host needs to connect to an external or public host. Conversely, DNAT translates a destination IP address when connecting from a public IP address to a private IP address, and is generally used to redirect a packets destined for a specific IP address to a different IP address.

## ipcalc

As an introduction, let's examine `192.168.0.133` via `ipcalc`:

```txt
ipcalc 192.168.0.133
Address:   192.168.0.133        11000000.10101000.00000000. 10000101
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   192.168.0.0/24       11000000.10101000.00000000. 00000000
HostMin:   192.168.0.1          11000000.10101000.00000000. 00000001
HostMax:   192.168.0.254        11000000.10101000.00000000. 11111110
Broadcast: 192.168.0.255        11000000.10101000.00000000. 11111111
Hosts/Net: 254                   Class C, Private Internet
```

Based on `ipcalc`'s output, we learn...

* `192.168.0.133` falls within a network, represented in CIDR notation as `192.168.0.0/24`.
* `192.168.0.133` (and the other IPs in its `192.168.0.0/24` network) is a "Class C, Private Internet" address, indicating it lives within the RFC 1918 "reserved private" class C block (see "Private networks" below for more on [RFC 1918](https://datatracker.ietf.org/doc/html/rfc1918) addresses).
* `192.168.0.1` is the first host in the network.
* `192.168.0.254` is the last host in the network.
* Note that the first value in the host field, 0, is always reserved as the network address. The network address identifies the network segment (the last bits in the network address must be zeros)
* The last value in the host field, 255, is always reserved for the broadcast address. The broadcast address is used for addressing all the nodes in the network at the same time.
* Disincluding the network address and broadcast addresses, the `192.168.0.0/24` network includes 254 individual host addresses (rather than 256).
* `255.255.255.0` is the _netmask_ (Or, depending on context, the _subnet mask_). For IPv4, in addition to a CIDR notation, a network may also be characterized by its subnet mask or netmask, which is the [bitmask](https://en.wikipedia.org/wiki/Mask_(computing)) that, when applied by a [bitwise `AND`](https://en.wikipedia.org/wiki/Bitwise_operation#AND) operation to any IP address in the network, yields the routing prefix.
* The 24-bit netmask (represented by `/24`) covers the first 3 quads, which make up the network ID, while the last quad is the host address.

Also note the right column in the output above, which shows each octet's 8 bit binary value. For example, the `11000000.10101000.00000000. 10000101` in the output's first line:

```txt
ipcalc 192.168.0.133
Address:   192.168.0.133        11000000.10101000.00000000. 10000101
...
```

[cidr.xyz](https://cidr.xyz/) is a good tool for visualizing this, too.

According to `ipcalc --help`...

> Look at the space between the bits of the addresses: The bits before it are the network part of the address, the bits after it are the host part. You can see two simple facts: In a network address all host bits are zero, in a broadcast address they are all set.

With that in mind, let's re-examine the far right column of `ipcalc` output. Note the addresses where the host bits are all zero. Note the addresses where the host bits are all set:

```txt
ipcalc 192.168.0.133
Address:   192.168.0.133        11000000.10101000.00000000. 10000101
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   192.168.0.0/24       11000000.10101000.00000000. 00000000
HostMin:   192.168.0.1          11000000.10101000.00000000. 00000001
HostMax:   192.168.0.254        11000000.10101000.00000000. 11111110
Broadcast: 192.168.0.255        11000000.10101000.00000000. 11111111
Hosts/Net: 254                   Class C, Private Internet
```

To examine your own public IP address:

```txt
ipcalc $(curl ifconfig.me/ip)
```

## Subnets

`ipcalc` can also assist in granularly subdividing networks into multiple subnets, as is common when logically subdividing private networks.

For example, let's attempt to carve out a subnet composed of 15 addresses from `172.20.1.0/24` (itself a class B private network block):

```txt
ipcalc 172.20.1.0/24 --split 15
Address:   172.20.1.0           10101100.00010100.00000001. 00000000
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   172.20.1.0/24        10101100.00010100.00000001. 00000000
HostMin:   172.20.1.1           10101100.00010100.00000001. 00000001
HostMax:   172.20.1.254         10101100.00010100.00000001. 11111110
Broadcast: 172.20.1.255         10101100.00010100.00000001. 11111111
Hosts/Net: 254                   Class B, Private Internet

1. Requested size: 15 hosts
Netmask:   255.255.255.224 = 27 11111111.11111111.11111111.111 00000
Network:   172.20.1.0/27        10101100.00010100.00000001.000 00000
HostMin:   172.20.1.1           10101100.00010100.00000001.000 00001
HostMax:   172.20.1.30          10101100.00010100.00000001.000 11110
Broadcast: 172.20.1.31          10101100.00010100.00000001.000 11111
Hosts/Net: 30                    Class B, Private Internet

Needed size:  32 addresses.
Used network: 172.20.1.0/27
Unused:
172.20.1.32/27
172.20.1.64/26
172.20.1.128/25
```

Based on `ipcalc`'s output, we learn...

* `172.20.1.0/24` (the original block) is itself composed of 254 hosts
* `172.20.1.0/27` offers a 30 host subnet meeting our needs (and providing adequate headroom to grow via twice the hosts we currently need)
* this leaves 3 additional subnets of available IPs: `172.20.1.32/27` (30 hosts), `172.20.1.64/26` (62 hosts), `172.20.1.128/25` (126 hosts)

Alternatively, let's attempt to carve out 2 subnets of 15 and 62 hosts, respectively, from the original `172.20.1.0/24` block:

```txt
$ ipcalc 172.20.1.0/24 --split 15 62
Address:   172.20.1.0           10101100.00010100.00000001. 00000000
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   172.20.1.0/24        10101100.00010100.00000001. 00000000
HostMin:   172.20.1.1           10101100.00010100.00000001. 00000001
HostMax:   172.20.1.254         10101100.00010100.00000001. 11111110
Broadcast: 172.20.1.255         10101100.00010100.00000001. 11111111
Hosts/Net: 254                   Class B, Private Internet

1. Requested size: 15 hosts
Netmask:   255.255.255.224 = 27 11111111.11111111.11111111.111 00000
Network:   172.20.1.64/27       10101100.00010100.00000001.010 00000
HostMin:   172.20.1.65          10101100.00010100.00000001.010 00001
HostMax:   172.20.1.94          10101100.00010100.00000001.010 11110
Broadcast: 172.20.1.95          10101100.00010100.00000001.010 11111
Hosts/Net: 30                    Class B, Private Internet

2. Requested size: 62 hosts
Netmask:   255.255.255.192 = 26 11111111.11111111.11111111.11 000000
Network:   172.20.1.0/26        10101100.00010100.00000001.00 000000
HostMin:   172.20.1.1           10101100.00010100.00000001.00 000001
HostMax:   172.20.1.62          10101100.00010100.00000001.00 111110
Broadcast: 172.20.1.63          10101100.00010100.00000001.00 111111
Hosts/Net: 62                    Class B, Private Internet

Needed size:  96 addresses.
Used network: 172.20.1.0/25
Unused:
172.20.1.96/27
172.20.1.128/25
```

## Additional features

Deaggregate an IP range into a CIDR:

```txt
ipcalc 1.2.168.0 - 1.2.169.255
deaggregate 1.2.168.0 - 1.2.169.255
1.2.168.0/23
```
## IPv6

Much of the above focuses on IPv4. Note that IPv6 is its own beast, and that `ipcalcv6` is a thing.

## Futher reading

* https://gist.github.com/LuoZijun/df2d57ab6f5217a4bd18
* https://github.com/nmav/ipcalc
* https://www.linux.com/topic/networking/how-calculate-network-addresses-ipcalc/

+++
title = "Juniper SRX PBA NAT"
date = 2021-05-02
draft = false
tags = ["nat", "ipv4", "juniper", "junos", "cg-nat", "srx", "networking"]
+++

## IPv4, NAT and CG-NAT

NAT is used by different service providers to allow a better "scalability" of IPv4.

The world would be definitely better with full IPv6 support, both for services and devices. However, unfortunately, an IPv6-only network nowadays it's almost impossible.

There are multiple technologies to allow the IPv6 transition. However, for some (small) operators, the only way to have more customers is to use NAT44 to allow them to surf the Internet.

This can be done with CG-NAT (Carrier Grade NAT) - which is only a buzzword that means "Scalable NAT / Large Scale NAT".

## NAT Logging criticalities

One of the criticalities of the (Source) NAT44, especially for the smallest ISP, is the logging of the NAT mappings (i.e., for law requirements).

With "standard" Source NAT44, every session is mapped to a different source (IP and) port. The port is randomly chosen by the NAT device. That means every single session (and related NAT mapping) must be logged.

However, a NAT "Configuration" called **PBA-NAT** (Port-Block Allocation NAT) allows for better log scalability. With **PBA-NAT**, the NAT equipment allocates a Port Block range to every different (active) client, keeping it allocated for a certain amount of time.
Then, every session coming from that client during that time, will use one of the ports of that block. This means that, for NAT tracking purposes, you only need to log the Port Block Allocation (and De-Allocation).

## PBA NAT and vSRX

Juniper SRX (and vSRX) allows the **PBA-NAT** configuration. Let's see an example.

Starting with basic IP and routing configurations, where my "Internet" is located on *ge-0/0/0*, and my "Customers" on *ge-0/0/1*:
```
set interfaces ge-0/0/0 unit 0 family inet address 172.23.131.20/24
set interfaces ge-0/0/1 unit 0 family inet address 10.248.0.1/24
set routing-options static route 0.0.0.0/0 next-hop 172.23.131.1
```

For this example, I'm allowing all traffic from internal network to the internet:
```
set security zones security-zone trust host-inbound-traffic system-services ping
set security zones security-zone trust interfaces ge-0/0/1.0
set security zones security-zone untrust host-inbound-traffic system-services ping
set security zones security-zone untrust interfaces ge-0/0/0.0

set security policies from-zone trust to-zone untrust policy default-permit match source-address any
set security policies from-zone trust to-zone untrust policy default-permit match destination-address any
set security policies from-zone trust to-zone untrust policy default-permit match application any
set security policies from-zone trust to-zone untrust policy default-permit then permit
```

Now I'll define the NAT Source Pool and NAT rules, using as "external" IP addresses the range *172.23.131.21-172.23.131.25*. Since these addresses are not configured on the *ge-0/0/0*, I'll start with a *proxy-arp* configuration.
```
set security nat proxy-arp interface ge-0/0/0.0 address 172.23.131.21/32 to 172.23.131.25/32

set security nat source pool pba-1 address 172.23.131.21/32 to 172.23.131.25/32
set security nat source pool pba-1 port block-allocation block-size 128
set security nat source pool pba-1 port block-allocation maximum-blocks-per-host 8
set security nat source pool pba-1 port block-allocation interim-logging-interval 1800
set security nat source pool pba-1 port block-allocation last-block-recycle-timeout 120
set security nat source port-randomization disable
set security nat source address-persistent

set security nat source rule-set source-nat-1 from zone trust
set security nat source rule-set source-nat-1 to zone untrust
set security nat source rule-set source-nat-1 rule r1 match source-address 10.248.0.0/16
set security nat source rule-set source-nat-1 rule r1 then source-nat pool pba-1
```

Finally, I'll define the log settings to capture the Port Block Allocation and De-Allocation. I am using a *syslog file* here, but you can send the logs to any desired destination.
```
set system syslog file nat-log any any
set system syslog file nat-log match RT_SRC_NAT_PBA_
```

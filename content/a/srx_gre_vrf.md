+++
title = "Juniper SRX, GRE and VRF (routing-instance) issue"
date = 2021-05-04
draft = false
tags = ["gre", "ipv4", "juniper", "junos", "vrf", "srx", "networking"]
+++

## GRE and VRF (Routing Instances)

There are some cases where you may want to create a GRE Tunnel from the default VRF (routing-instance), but to have the GRE traffic inside another - dedicated - instance.

Unfortunately, while testing it, I found some issues on vSRX (both on AWS and on VMWare ESXi).

## Configuration and Problem

I configured my vSRX in that way:
```
set interfaces ge-0/0/0 unit 0 family inet address 10.250.28.20/26

set interfaces gr-0/0/0 unit 1 tunnel source 10.250.28.20
set interfaces gr-0/0/0 unit 1 tunnel destination 10.250.26.10
set interfaces gr-0/0/0 unit 1 family inet address 10.211.23.1/30

set routing-options static route 10.250.24.0/21 next-hop 10.250.28.1

set routing-instances SGI instance-type virtual-router
set routing-instances SGI interface gr-0/0/0.1

set security zones security-zone Local-VPC host-inbound-traffic system-services all
set security zones security-zone Local-VPC host-inbound-traffic protocols all
set security zones security-zone Local-VPC interfaces ge-0/0/0.0

set security zones security-zone SGI-PGW host-inbound-traffic system-services ping
set security zones security-zone SGI-PGW interfaces gr-0/0/0.1
```

Unfortunately, with such configuration, I am not able to ping (or have any other traffic) inside the tunnel.

However, if I remove the "membership" of the GRE tunnel from the routing-instance, everything works fine.

Basically, this is the configuration statement that breaks everything:
```
set routing-instances SGI interface gr-0/0/0.1
```

It seems that the GRE engine is not able to reach the GRE endpoint, because it tries to send out the packet looking up the routing-instance's route table, instead of *inet.0*.

## Workaround

The workaround for the problem is the following configuration:
```
set routing-instances SGI routing-options static route 10.250.26.10/32 next-table inet.0
```
With such configuration, the GRE endpoint is reachable, and everything works fine!

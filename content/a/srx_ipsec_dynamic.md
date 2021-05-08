+++
title = "Juniper SRX Site-to-Site VPN with dynamic peers"
date = 2021-05-08
draft = false
tags = ["ipsec", "ikev2", "juniper", "junos", "tunnel", "srx", "networking"]
+++

## Introduction

I had to create a configuration for Site-to-Site VPN using vSRX, with a Hub location (with static/public IP address) and some Spoke locations with dynamic IP addresses, and some of them behind NAT.

This is the relevant configuration I adopted, based on IKEv2 (PSK authentication), interface tunnels and BGP.

## Hub Configuration

```
set security ike proposal prop-phase1 authentication-method pre-shared-keys
set security ike proposal prop-phase1 dh-group group2
set security ike proposal prop-phase1 authentication-algorithm sha-256
set security ike proposal prop-phase1 encryption-algorithm aes-256-cbc
set security ike proposal prop-phase1 lifetime-seconds 28800

set security ike policy pol-phase1 proposals prop-phase1
set security ike policy pol-phase1 pre-shared-key ascii-text XXXXXXXXX

set security ike gateway hub-spoke-1 ike-policy pol-phase1
set security ike gateway hub-spoke-1 dynamic hostname SRX-SPOKE-1
set security ike gateway hub-spoke-1 local-identity hostname SRX-HUB
set security ike gateway hub-spoke-1 external-interface ge-0/0/0.0
set security ike gateway hub-spoke-1 version v2-only

set security ipsec proposal prop-phase2 protocol esp
set security ipsec proposal prop-phase2 authentication-algorithm hmac-sha1-96
set security ipsec proposal prop-phase2 encryption-algorithm aes-256-cbc
set security ipsec proposal prop-phase2 lifetime-seconds 3600

set security ipsec policy pol-phase2 proposals prop-phase2

set security ipsec vpn hub-spoke-1 bind-interface st0.2
set security ipsec vpn hub-spoke-1 ike gateway hub-spoke-1
set security ipsec vpn hub-spoke-1 ike proxy-identity service any
set security ipsec vpn hub-spoke-1 ike ipsec-policy pol-phase2

set security zones security-zone Internet host-inbound-traffic system-services ping
set security zones security-zone Internet host-inbound-traffic system-services ike
set security zones security-zone Internet interfaces ge-0/0/0.0

set security zones security-zone VPN host-inbound-traffic system-services ping
set security zones security-zone VPN host-inbound-traffic protocols bgp
set security zones security-zone VPN interfaces st0.2

set interfaces st0 unit 2 family inet address 10.211.208.253/30

set routing-options autonomous-system 65000
set protocols bgp group spoke type external
set protocols bgp group spoke peer-as 64001
set protocols bgp group spoke neighbor 10.211.208.254
```

## Spoke Configuration

```
set security ike proposal prop-phase1 authentication-method pre-shared-keys
set security ike proposal prop-phase1 dh-group group2
set security ike proposal prop-phase1 authentication-algorithm sha-256
set security ike proposal prop-phase1 encryption-algorithm aes-256-cbc
set security ike proposal prop-phase1 lifetime-seconds 28800

set security ike policy pol-phase1 proposals prop-phase1
set security ike policy pol-phase1 pre-shared-key ascii-text XXXXXXXXX

set security ike gateway hub-spoke-1 ike-policy pol-phase1
set security ike gateway hub-spoke-1 address 11.22.33.44
set security ike gateway hub-spoke-1 local-identity hostname SRX-SPOKE-1
set security ike gateway hub-spoke-1 remote-identity hostname SRX-HUB
set security ike gateway hub-spoke-1 external-interface ge-0/0/0.0
set security ike gateway hub-spoke-1 version v2-only

set security ipsec proposal prop-phase2 protocol esp
set security ipsec proposal prop-phase2 authentication-algorithm hmac-sha1-96
set security ipsec proposal prop-phase2 encryption-algorithm aes-256-cbc
set security ipsec proposal prop-phase2 lifetime-seconds 3600

set security ipsec policy pol-phase2 proposals prop-phase2

set security ipsec vpn hub-spoke-1 bind-interface st0.2
set security ipsec vpn hub-spoke-1 ike gateway hub-spoke-1
set security ipsec vpn hub-spoke-1 ike proxy-identity service any
set security ipsec vpn hub-spoke-1 ike ipsec-policy pol-phase2
set security ipsec vpn hub-spoke-1 establish-tunnels immediately

set security zones security-zone Internet host-inbound-traffic system-services ping
set security zones security-zone Internet host-inbound-traffic system-services ike
set security zones security-zone Internet interfaces ge-0/0/0.0
set security zones security-zone VPN host-inbound-traffic system-services ping
set security zones security-zone VPN host-inbound-traffic protocols bgp
set security zones security-zone VPN interfaces st0.2

set interfaces st0 unit 2 family inet address 10.211.208.254/30

set policy-options policy-statement local-nets term r1 from route-filter 10.201.0.0/16 orlonger
set policy-options policy-statement local-nets term r1 then accept

set routing-options autonomous-system 64001
set protocols bgp group hub type external
set protocols bgp group hub export local-nets
set protocols bgp group hub peer-as 65000
set protocols bgp group hub neighbor 10.211.208.253
```

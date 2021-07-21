+++
title = "Mikrotik Site-to-Site VPN with dynamic peers (IKEv2)"
date = 2021-07-21
draft = false
tags = ["ipsec", "ikev2", "mikrotik", "routeros", "networking"]
+++

## Introduction

I had to create a configuration for Site-to-Site VPN using Mikrotik, with a Hub location (with static/public IP address) and some Spoke locations with dynamic IP addresses, and some of them behind NAT.

![Topology](topology.png#mid)

This is the relevant configuration I adopted, based on IKEv2 (PSK authentication).

This post is similar to [this one, based on Juniper SRX]({{< ref "srx_ipsec_dynamic.md" >}}).

The policies on the HUB Router are automatically generated from the Spokes' policies.

## Hub Configuration

```
/system identity
set name=HUB

/interface bridge
add name=Loopback protocol-mode=none
/ip address
add address=10.0.0.1/30 interface=ether2
add address=192.168.255.1 interface=Loopback

/ip ipsec peer
add exchange-mode=ike2 name=DynamicIP passive=yes send-initial-contact=no

/ip ipsec identity
add generate-policy=port-override my-id=fqdn:hub.vpn.network peer=DynamicIP \
    remote-id=fqdn:peer1.vpn.network secret=Banana123
add generate-policy=port-override my-id=fqdn:hub.vpn.network peer=DynamicIP \
    remote-id=fqdn:peer2.vpn.network secret=Banana123

/ip firewall nat
add action=accept chain=srcnat dst-address=192.168.0.0/16 src-address=192.168.0.0/16
```

## Spoke 1 Configuration

```
/system identity
set name=SPOKE1

/interface bridge
add name=Loopback protocol-mode=none
/ip address
add address=192.168.1.1 interface=Loopback

/ip ipsec peer
add address=10.0.0.1 exchange-mode=ike2 name=hub

/ip ipsec identity
add my-id=fqdn:peer1.vpn.network peer=hub remote-id=fqdn:hub.vpn.network secret=Banana123

/ip ipsec policy
add dst-address=192.168.255.0/24 peer=hub src-address=192.168.1.0/24 tunnel=yes

/ip firewall nat
add action=accept chain=srcnat dst-address=192.168.0.0/16 src-address=192.168.0.0/16
```

## Spoke 2 Configuration

```
/system identity
set name=SPOKE2

/interface bridge
add name=Loopback protocol-mode=none
/ip address
add address=192.168.2.1 interface=Loopback

/ip ipsec peer
add address=10.0.0.1 exchange-mode=ike2 name=hub

/ip ipsec identity
add my-id=fqdn:peer2.vpn.network peer=hub remote-id=fqdn:hub.vpn.network secret=Banana123

/ip ipsec policy
add dst-address=192.168.255.0/24 peer=hub src-address=192.168.2.0/24 tunnel=yes

/ip firewall nat
add action=accept chain=srcnat dst-address=192.168.0.0/16 src-address=192.168.0.0/16
```
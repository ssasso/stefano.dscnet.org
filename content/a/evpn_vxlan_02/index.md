+++
title = "EVPN and VXLAN Episode 2: EVPN Route Types and routing"
date = 2021-11-08
draft = false
tags = ["evpn", "vxlan", "bgp", "datacenter", "overlay", "nvo", "dell", "dellos10", "os10", "arista", "veos"]
categories = []

+++

In the <u>[previous episode]({{< ref "evpn_vxlan_01" >}} "The magic world of EVPN and VXLAN (EVPN and VXLAN Episode 1)")</u> we created a very simple topology, and we started talking about EVPN Routes of Type-3 and Type-2. However, multiple route types for EVPN are defined by the standards:
* **Type 1**: Ethernet Auto-Discovery (A-D) route
* **Type 2**: MAC/IP advertisement route
* **Type 3**: Inclusive Multicast
* **Type-4**: Ethernet Segment route
* **Type-5**: IP Prefix route

Type-1 and Type-4 routes are used in *EVPN Multi-Homing* scenarios, which we’ll expand in another episode, dedicated to Leaf redundancy.

Here we will focus on **Type-2** and **Type-3**, which are the common ones for Layer 2 encapsulation service.

Additional route types also exist for multicast switching/routing.

Let’s start with **Type-3**: they are used by the different VTEPs to advertise each Layer 2 VNI (and the related VTEP IP Address) to each other, in fact to implement VTEP auto-discovery. This is useful to create an “ingress replication list”, which is the list of VTEPs where to send the BUM traffic (Broadcast, Unknown Unicast, and Multicast).

![Type-3 Route](Type_3.png#sixhundreds)

The UPDATE of a Type-3 route is composed by a *NLRI*, and a so-called *PSMI* attribute (Provider Multicast Service Interface).
The Route Distinguisher, VNI and the VTEP IP Address information are signaled.
Also, please note that Extended BGP Communities are in use to signal the RD (Route Distinguisher) and RT (Route Target).

**Type-2** Routes instead, as the name recalls, are used to advertise MAC Addresses for a specific VNI.

![Type-2 Route](Type_2_MAC.png#sixhundreds)

Type-2 Routes also allow to announce associations between MAC addresses and IP addresses (practically, the ARP/neigh table). In this way you can easily gain ARP broadcast suppression.

![Type-2 Route](Type_2_MAC_IP.png#sixhundreds)

This can happen when you start putting Layer 3 into the game, assigning an IP address to the “Virtual Network”.

Let’s start again from the previous topology, and let’s introduce the concept of Distributed vs Centralized routing:

![Initial Testbed](First_Topology.png#small)

If we want the two hosts, having addresses in the 192.168.0.0/24 subnet, to reach the external world, we need to set-up a route on them. A “router” must be placed between them and the external world we want to reach.

This router can be a device placed “outside” the VXLAN/EVPN domain, with interfaces in the relevant VXLAN networks (centralized / external routing):

![External Routing](External_Routing.png#small)

This will work, of course, “out of the box”. Since we are extending our Layer 2 domain, nothing new, nothing special. The “gateway” will be resolved with the MAC address of the router, and the ethernet frames will be sent to it.

On the other hand, distributed routing, or even inter-VXLAN routing, can happen directly on the Leafs.
If every leaf in the topology has a VRF with the different routes to the different Virtual Networks, it’s easy to perform the lookup and the routing.
But, for this to work, you must assign an IP address to every Leaf you want to be the “gateway” for your servers.
And, if you want to use only static routing on your servers, you can even assign the same - virtual - IP address to all the leafs!

On Dell OS10 the configuration is straightforward:

```
ip vrf TEST
!
ip virtual-router mac-address 00:00:aa:bb:02:cc
!
interface virtual-network 10
 no shutdown
 ip vrf forwarding TEST
 ip address 192.168.0.201/24
 ip virtual-router address 192.168.0.254
!
```

After assigning the IP addresses to the Leafs, on a dedicated VRF, we can see that the IP-MAC association are propagated using EVPN Type-2 routes:

![Type-2 Route](Dell_Type_2.png#mid)

Ok, and what happens when you need to achieve inter-VXLAN routing?
We can expand our basic topology:

![Inter-VXLAN Basic Routing](Inter_VXLAN_Routing_base.png#small)

Imagine you have to ping *192.168.20.2* from *192.168.0.1*.
The ICMP Echo starting from *192.168.0.1* arrives at the Leaf 1. Leaf 1 does a route table lookup, and sees that *192.168.20.0/24* is reachable using the *Virtual Network 20*:

![Routing Table](Leaf_1_Routing.png#mid)

On the *Virtual Network 20*, there is an ARP entry for *192.168.20.2*, which shall be encapsulated on *VXLAN VNI 20* and sent to Leaf 2. On Leaf 2, the packet is switched to the local interface.

On the way back, Leaf 2 performs a route table lookup for the ICMP Echo Reply, and sees that *192.168.0.1* is reachable using the *Virtual Network 10*.
The packet is encapsulated into *VXLAN VNI 10* and sent to Leaf 1, which performs standard switching to the local interface.

![Wireshark Trace](Wireshark_Asymm.png#mid)

This is called **Asymmetric Routing** (because different VNIs are used for the two traffic directions: <u>routing is performed on the ingress leaf, and switching on the egress one</u>).

Ok, also this time we are set with theory and different notions.

Let’s conclude with a very basic configuration for another vendor, this time *Arista vEOS*, for our very basic simple topology.
Reporting here only a single Leaf configuration.

```
! Command: show running-config
! device: AR-SW-1 (vEOS-lab, EOS-4.27.0F)
!
service routing protocols model multi-agent
!
hostname AR-SW-1
!
vlan 10,20
!
vrf instance TEST
!
interface Ethernet1
   switchport access vlan 10
!
interface Ethernet2
   switchport access vlan 20
!
interface Ethernet9
   no switchport
   ip address 10.255.255.1/30
!
interface Loopback0
   ip address 10.0.0.1/32
!
interface Vlan10
   vrf TEST
   ip address 192.168.0.201/24
   ip virtual-router address 192.168.0.254
!
interface Vlan20
   vrf TEST
   ip address 192.168.20.201/24
   ip virtual-router address 192.168.20.254
!
interface Vxlan1
   vxlan source-interface Loopback0
   vxlan udp-port 4789
   vxlan vlan 10 vni 10
   vxlan vlan 20 vni 20
   vxlan learn-restrict any
!
ip virtual-router mac-address 00:00:aa:bb:02:cc
!
ip routing
ip routing vrf TEST
!
ip route 10.0.0.2/32 10.255.255.2
!
router bgp 65000
   router-id 10.0.0.1
   no bgp default ipv4-unicast
   neighbor 10.0.0.2 remote-as 65000
   neighbor 10.0.0.2 update-source Loopback0
   neighbor 10.0.0.2 bfd
   neighbor 10.0.0.2 send-community extended
   !
   vlan 10
      rd auto
      route-target both 10:10
      redistribute learned
   !
   vlan 20
      rd auto
      route-target both 20:20
      redistribute learned
   !
   address-family evpn
      neighbor 10.0.0.2 activate
!
```

As you can see, also here we can find Type-3 and Type-2 routes:

![Arista EVPN](Arista_MAC_IP.png#mid)

We can also print extended details:

![Arista EVPN Details](Arista_VNI_10_Details.png#mid)


Since we feel brave, we can even try to connect a *Dell OS10* Leaf with an *Arista vEOS* Leaf.

A key difference between Dell and Arista is that on *Dell OS10* Route Targets are automagically set, while on *Arista vEOS* we explicitly configured them.
Adjusting the RT on Arista should give us the interoperability between the two.

In details, *Dell OS10* uses the following RT for *VNI 10*, as we can see on one of the announces received on the Arista: **0:268435466**

![Dell Announce on Arista](Arista_Dell_RT.png#mid)

Let’s update our configuration on Arista, then:
```
router bgp 65000
   !
   vlan 10
      route-target import 0:268435466
      route-target export 0:268435466
   !
```

Wooooow, it works!

This is the EVPN Route Table on the Dell Leaf:

![Dell EVPN Route Table](Dell_Arista_EVPN.png#mid)

And we can ping between two VMs connected to the different Leafs.

![Ping Arista Dell](Ping_Arista_Dell_Trace.png#mid)

![Ping Arista Dell](Ping_Arista_Dell.png#mid)

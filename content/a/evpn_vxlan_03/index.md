+++
title = "EVPN and VXLAN Episode 3: Symmetric IRB"
date = 2021-12-04
draft = false
tags = ["evpn", "vxlan", "bgp", "datacenter", "overlay", "nvo", "dell", "dellos10", "os10", "arista", "veos"]
categories = []

+++
In the <u>[previous episode]({{< ref "evpn_vxlan_02" >}} "EVPN and VXLAN Episode 2: EVPN Route Types and routing")</u> we saw how two hosts, on different VLANs (VXLANs), can talk each other if they are on the same VRF.
In details, we talked about the **Asymmetric Routing model** (because different VNIs are used for the two traffic directions: <u>routing is performed on the ingress leaf, and switching on the egress one</u>).

However, another method exists for achieving routing between two VXLAN segments, which is... guess what? **Symmetric Routing** (or Symmetric IRB, where *IRB = Integrated Routing and Bridging*).

With the Symmetric Routing model, every VRF on our fabric will be associated to an additional VNI ("Layer 3 VNI" - which can be seen more or less like the *Service Label* on MPLS)
which will be used to send the routed packets over the fabric (and route over VTEPs).

A single VNI for the packets going back and forth is not the only benefit of the Symmetric Routing model: 
with the Asymmetric model, you should create/propagate the different VXLAN "segments" on every device of the fabric where you want to route your packets, even if there are no hosts for that VXLAN connected on the device. 
With the Symmetric Routing model, this is not needed anymore: only the Layer 3 VNI is propagated on the different fabric devices.


Let’s see how this works with our previous topology:

![Inter-VXLAN Basic Routing](EVPN-VXLAN-Various-Arista-Symm-1.png#small)


Imagine you have to ping *192.168.20.2* from *192.168.0.1*.

The ICMP Echo starting from *192.168.0.1* arrives at the Leaf 1 (*AR-SW-1*). Leaf 1 does a route table lookup, and sees that *192.168.20.0/24* is reachable using the Symmetric Routing model, using the L3 VNI (in example) *6000*.

Leaf 1 encapsulates the packet on VXLAN VNI 6000.

But... VXLAN requires an Ethernet header to be present. For that, Leaf 1 forges the Ethernet header using the Leaf 2 "*Router MAC Address*" as destination MAC, and its "*Router MAC Address*" as source MAC.

Now the Leaf 2 receives the packet, it looks at the VNI and the destination MAC address, and understands that it has to route it.
It does a routing table lookup, and defines how to send out the packet.

On the way back, Leaf 2 does exactly the same operation (inverting the two VXLAN MAC addresses, of course).

The different "*Router MAC Address*" are signaled using BGP extended communities: we can see that our Type-2 announcements are a bit different:

![Symmetric Type-2](Symmetric-Type-2.png#sixhundreds)

(The first VNI carried on the message is the Layer 2 VNI, and the second one is the Layer 3 VNI)

Let’s verify this directly in the Lab: we can use a topology similar to the previous one, but entirely based on two Arista Leafs.
We should start with porting and adapting the configuration we did on the previous episode to include the L3 VNI info. At the same time, we can start using OSPF to announce our loopback addresses (and improve a bit the potential scalability).

The following configuration example is referred to Leaf-1:

```
!
service routing protocols model multi-agent
!
hostname AR-SW-1
!
vlan 10
!
vrf instance TEST
!
interface Ethernet1
   switchport access vlan 10
!
interface Ethernet9
   no switchport
   ip address 10.255.255.1/30
   ip ospf area 0.0.0.0
!
interface Loopback0
   ip address 10.0.0.1/32
   ip ospf area 0.0.0.0
!
interface Vlan10
   vrf TEST
   ip address 192.168.0.201/24
   ip virtual-router address 192.168.0.254
!
interface Vxlan1
   vxlan source-interface Loopback0
   vxlan udp-port 4789
   vxlan vlan 10 vni 10
   vxlan vrf TEST vni 6000
   vxlan learn-restrict any
!
ip virtual-router mac-address 00:00:aa:bb:02:cc
!
ip routing
ip routing vrf TEST
!
router ospf 1
   passive-interface Loopback0
!
router bgp 65000
   router-id 10.0.0.1
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   neighbor 10.0.0.2 remote-as 65000
   neighbor 10.0.0.2 next-hop-self
   neighbor 10.0.0.2 update-source Loopback0
   neighbor 10.0.0.2 bfd
   neighbor 10.0.0.2 send-community extended
   !
   vlan 10
      rd auto
      route-target both 10:10
      redistribute learned
   !
   address-family evpn
      neighbor 10.0.0.2 activate
   !
   vrf TEST
      rd 10.0.0.1:6000
      route-target import evpn 65000:6000
      route-target export evpn 65000:6000
```

We can verify that the information about VNI *6000* is propagated:

![Symmetric Type-2](BGP-EVPN-Type-2.png#sixhundreds)

And host */32* routes are created on the VRF routing table to allow Inter-VXLAN routing:

![Symmetric Type-2](EVPN-Type-2-VRF.png#sixhundreds)

We can try a ping between two hosts on two different Layer 2 domains, connected to two different switches:

![Symmetric Ping](Type-2-Ping.png#mid)

As you can see, the VXLAN VNI is set to 6000.

**To recap**: <u>When using Symmetric Routing, the ingress VTEP does not require L3 presence on the destination subnet, and the egress VTEP does not require L3 presence on the source subnet.</u>

**ASYMMETRIC ROUTING:**

![Asymmetric IRB](EVPN-VXLAN-Various-Rout-Model-Asy.png#sixhundreds)

**SYMMETRIC ROUTING:**

![Symmetric IRB](EVPN-VXLAN-Various-Rout-Model-Sy.png#sixhundreds)

In one of their documents, *Arista* also says:

> Note: Symmetric IRB is recommended, as it does not require that all VLANs and VRFs exist everywhere to guarantee host reachability.
> Additionally, with Symmetric IRB, Remote ARP entries are maintained in software instead of consuming hardware resources.
> Thus making it a more scalable solution.


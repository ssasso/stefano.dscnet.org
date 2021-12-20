+++
title = "EVPN and VXLAN Episode 4: Routing into and out of the EVPN network"
date = 2021-12-19
draft = false
tags = ["evpn", "vxlan", "bgp", "datacenter", "overlay", "nvo", "dell", "dellos10", "os10", "arista", "veos"]
series = ["evpn"]
categories = []

+++
In the <u>[previous episodes]({{< ref "/page/evpnseries" >}} "VXLAN and EVPN Series")</u> we discussed about how it is possible to route packets in and out of the fabric using an external routers with multiple legs into different VXLAN Layer 2 bridging domains,
and we also talked about Asymmetric and Symmetric **Integrated Routing and Bridging (IRB)** to route the traffic between VXLAN domains.

But, what happens when we want to route from and to different "external" subnets from different Leafs? And how does this marry with Symmetric IRB, to allow better scalability?

Here is where **Type-5 Routes** start to play their role. As we previously stated, Type-5 Routes are used to announce entire subnets inside the EVPN Fabric - and the Symmetric IRB configuration is a foundation for that.

We defined a L3 VNI for our VRFs... and now, still using BGP, we can inject multiple routes into it.

Starting from the setup of the previous episode, let’s connect a Virtual *Mikrotik CHR* Router to an interface of our first Arista Leaf:

![Topology](topology_4.png#small)

We will configure the *Mikrotik* to BGP peer with it, and to announce an external network/address (that we would configure on a loopback interface). Here's the relevant config:
```
/interface bridge
add name=loopback protocol-mode=none

/ip address
add address=192.168.254.1/30 interface=ether1
add address=10.20.30.40 interface=loopback

/routing bgp instance
set default as=64999

/routing bgp network
add network=10.20.30.40/32

/routing bgp peer
add name=ARISTA-1 remote-address=192.168.254.2 remote-as=65000
```

Let’s add the following statements to our Arista (*Leaf-1*) configuration:
```
interface Ethernet3
  no switchport
  description Link_to_CHR
  vrf TEST
  ip address 192.168.254.2/30
!
router bgp 65000
  vrf TEST
    neighbor 192.168.254.1 remote-as 64999
    redistribute connected
    !
    address-family ipv4
      neighbor 192.168.254.1 activate
!
```

As you can see, we also set the "redistribute connected" statement: that configuration will announce a Type-5 Route also for the directly connected networks, including all the VXLAN interfaces subnets.

We can verify the routing table on Leaf-1:

![Leaf-1-Routes](Leaf-1-Routes.png#mid)

We can see the related Type-5 announcement:

![Type-5-Details](Type-5-Details.png#sixhundreds)

and the reflected entries on the Leaf-2 BGP EVPN table and routing table:

![Leaf-2-EVPN](Leaf-2-EVPN.png#mid)

![Leaf-2-Routes](Leaf-2-Routes.png#mid)

Of course, we expect a ping to work:

![ICMP](ICMP.png#mid)

This has been quick! :-)
But in the next episodes we'll go deeper on the different deployment models, redundancy and scalability. Stay tuned!

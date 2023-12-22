+++
title = "Multi Vendor EVPN and VXLAN Fabric"
date = 2023-12-22
draft = true
tags = ["evpn", "vxlan", "bgp", "datacenter", "overlay", "nvo", "dell", "dellos10", "os10", "aruba", "arubacx", "cx", "containerlab", "netlab", "netsim-tools", "hpe", "hpearuba", "hpearubanetworking"]
series = ["evpn"]
categories = []

+++

## Introduction

The [EVPN saga]({{< ref "/page/evpnseries" >}} "VXLAN and EVPN Series") is back!

The company where I work(ed) (*Athonet*) was mainly a Dell shop. In my team's Lab, we have a small Leaf/Spine EVPN Fabric composed of some *Dell S5200* and *S4100*, powered by *OS10*.

Since the company now became <u>Athonet, a Hewlett Packard Enterprise Acquisition</u>, we started to work intensively with **Aruba Switches**, powered by **ArubaOS-CX**.

We want, of course, to insert them in the existing fabric, starting from the Leaf switches.

For that reason I thought it could be good to do some interop testing using virtual devices before starting to work with the real gear.
And, obviously, I don't want to waste time with IP Address allocation, IP Address assignment to the different VIrtual Switches interfaces... So I will use [netlab](https://netlab.tools/) :innocent:

The different leaf switches are connected to the spines using IPv4 point to point interfaces, with */30 subnets*. OSPF is used to redistribute the loopback ip addresses, used for iBGP EVPN peerings and as VTEP addresses.

We are also using Dell MC-LAG implementation, VLT. And we will use Aruba's counterpart, VSX.

However, the initial interop test will be done only with "single" switches. Later on, VLT and VSX will be inserted into the picture. For that, I will write some custom templates for netlab, since it does not support LAG interfaces (for now :wink:)

You can find the netlab topologies I will use [here](https://github.com/ssasso/netsim-topologies/tree/main/multivendor-evpn).

For the testing I will be using **netlab with containerlab** (*vrnetlab*), using Dell OS10 version *10.5.6*, and Aruba AOS-CX version *10.13* (which does support L3VNI, yay! :sunglasses:).

## Test 0

Let's start with a very simple interconnection between a virtual switch running Dell OS10, and one running ArubaOS-CX. An OSPF session is being created, and a iBGP session on top of it.
Some routes are distributed via OSPF, others via BGP.

This topology can be found [here](https://github.com/ssasso/netsim-topologies/blob/main/multivendor-evpn/test0/topology.yml).

I thought this was simple...
But I started immediately facing a problem: the OSPF session was not coming up at all.

It was stuck on

![](t0/t0_1.png#mid)

![](t0/t0_2.png#mid)

So I first did a ping check, just to make sure the link is really up:

![](t0/t0_3.png#mid)

The first candidate when an OSPF session is not negotiating, is MTU. Let's check it.

On r1 (Dell OS10):

![](t0/t0_4.png#mid)

On r2 (Aruba CX):

![](t0/t0_5.png#mid)

Yap! That's the problem!

**It's always MTU!** :rofl:

I also verified it enabling OSPF debug on one side, i.e. on r2:

![](t0/t0_6.png#mid)

So, let's set the MTU directly on the netlab topology file.

(*default MTU of 1500 for clab has been set on a netlab patch - see below*)

Woah, still nothing.

![](t0/t0_7.png#mid)

Ok, that's the classical case of different vendors using the config keyword “MTU” for IP MTU vs L2 MTU.
In fact, Dell OS is reporting:

![](t0/t0_8.png#small)

Ok, let's try to manually change it.
Dell OS10 wants a MTU in the format `IP MTU + 32`.

![](t0/t0_9.png#small)

Et... Voilà! :upside_down_face:

![](t0/t0_10.png#mid)

Ok, let's fix the netlab topology file again (setting it as a default value for all the OS10 devices).

After running `netlab up` one more time, I can check the OSPF and BGP status, and the related routes:

![](t0/t0_11.png#mid)

![](t0/t0_12.png#mid)

We can also create a small "netlab validation" test (see [here](https://netlab.tools/topology/validate/)): [validate.yml](https://github.com/ssasso/netsim-topologies/blob/main/multivendor-evpn/test0/validate.yml).

![](t0/t0_13.png#mid)

Great! Let's move on. :cowboy_hat_face:

**NOTE**: I created a fix for this Dell OS10 MTU issue on [this github commit](https://github.com/ipspace/netlab/commit/f641bc000cc8809568efcab702a87dcd98b62142).


## Test 1

Now that we verified basic functionalities like OSPF and iBGP, we can start creati our EVPN Fabric.

Creating it using netlab, defining one VRF and 3 VLANs, and related VNIs, should be straightforward.

The initial topology file can be found [here](https://github.com/ssasso/netsim-topologies/blob/main/multivendor-evpn/test1/topology.yml).

This topology is composed of 2 Dell OS10 Spine switches, 1 Dell Leaf, 1 Aruba Leaf, and 4 Linux hosts:

* Two hosts (h1, h2) are on the same VLAN (red), but connected to the two different switches.
* Two hosts (h3, h4) are on different VLANs (blue, green) and on different switches.

The scope of this is to test both **L2VNI and L3VNI, with Symmetric IRB**.

**NOTE**: Since netlab creates an iBGP session between the two RR (the spines), I created a direct link between the two switches to avoid this session to go through leaf links.
In real world scenarios, spines are not connected to each-other, and an iBGP session between them shall not exist.

**First problem**.

OSPF session between L2 and S1, S2 is not coming up.

![](t1/t1_1.png#mid)

It seems we are facing the same MTU problem we encountered during *Test 0*! :expressionless: And this is confirmed by debug logs.

So, what happened now?

On *Test 0*, the test was performed using IP MTU value of 1500 (default value on AOS-CX).

Here, to allow VXLAN packets to flow without fragmentation, we **set the links IP MTU to 1600**.

The problem is that we need to force IP MTU on ArubaOS-CX:

![](t1/t1_2.png#small)

**NOTE**: I created a fix on netlab also for this on [this github commit](https://github.com/ipspace/netlab/commit/3e60b1a9552ea6d6e723ce28249d164aa6ce3116).

In fact, after setting it, the OSPF sessions are OK:

![](t1/t1_3.png#mid)

The BGP control plane seems all up and running as well:

![](t1/t1_4.png#mid)

So let's start some connectivity checks.

H1 is able to reach H2 (connected on the other switch):

![](t1/t1_5.png#mid)

We can say that L2VNI is working fine.

H1 is able to reach H3:

![](t1/t1_6.png#mid)

But this was really a simple test, H1 and H3 are connected on the same switch :slightly_smiling_face:

Let's try to reach H4 from H1:

![](t1/t1_7.png#mid)

Ouch, this is not working. :face_with_head_bandage:

If we try to reach H4 from H3, we will see the same problem.

On the control plane of both leaf switches, everything looks good:

![](t1/t1_8.png#mid)

![](t1/t1_9.png#mid)

From L1 we are able to reach H3:

![](t1/t1_10.png#mid)

And from L2 we are able to reach H4:

![](t1/t1_11.png#mid)

Ok, let's see what happens **between the two leaf switches**.

To simplify the troubleshooting, I stopped one of the two spine switches (spine 2), forcing all the traffic on a single link.

Then, thanks to containerlab, we can use **tcpdump** on a specific switch interface. In this case, I am sniffing on `ethernet 1/1/1` of the L1 leaf switch with the command:
```
ip netns exec clab-test1-l1 tcpdump -l -nni eth1 udp port 4789
```

Let's try again a ping from H3, and then from H4.

![](t1/t1_12.png#mid)

```
17:16:41.943582 IP 10.100.0.11.58693 > 10.100.0.12.4789: VXLAN, flags [I] (0x08), vni 200000
    IP 172.16.1.143 > 172.16.2.144: ICMP echo request, id 15, seq 0, length 64

17:16:42.940892 IP 10.100.0.11.58693 > 10.100.0.12.4789: VXLAN, flags [I] (0x08), vni 200000
    IP 172.16.1.143 > 172.16.2.144: ICMP echo request, id 15, seq 1, length 64

17:16:51.062123 IP 10.100.0.12.57966 > 10.100.0.11.4789: VXLAN, flags [I] (0x08), vni 3392
    IP 172.16.2.144 > 172.16.1.143: ICMP echo request, id 30, seq 0, length 64

17:16:52.061561 IP 10.100.0.12.57966 > 10.100.0.11.4789: VXLAN, flags [I] (0x08), vni 3392
    IP 172.16.2.144 > 172.16.1.143: ICMP echo request, id 30, seq 1, length 64
```

On the path H3 → H4, the ICMP echo request is correctly encapsulated with the VXLAN VNI set to `200000`.

But, on the other way (H4 → H3), we see that the ICMP echo request is encapsulated with a wrong VXLAN VNI: `3392` instead of `200000`!!

```
17:16:51.062123 IP 10.100.0.12.57966 > 10.100.0.11.4789: VXLAN, flags [I] (0x08), vni 3392
    IP 172.16.2.144 > 172.16.1.143: ICMP echo request, id 30, seq 0, length 64
```

This made me remember of a caveat that I found on ArubaOS-CX Virtual with L2VNIs: for some reason, the VNI ID cannot be so much bigger... otherwise it will overflow (on the dataplane) (see [here](https://netlab.tools/caveats/#aruba-aos-cx)).

Ok, we can easily solve it.

The default behavior for netlab L3VNI is to start allocating them from `200000`; 
Let's solve it by changing the default value of `start_transit_vni` as well (I changed it on the common default file) - setting it to `10000`.

```
defaults.vxlan.start_vni: 20000
defaults.evpn.start_transit_vni: 10000
```

Let's restart our lab topology. We can directly test with a ping between H3 and H4.

![](t1/t1_13.png#mid)

YAY!!!! Just to have a confirmation, let's start another tcpdump trace on L1 `ethernet 1/1/1` (*after shutting down again spine 2*):

![](t1/t1_14.png#mid)

SO FAR SO GOOD!


## Test 1.1

Let's try to add an external router, with a BGP peering to L2 (which acts as a border leaf).

The new topology is [here](https://github.com/ssasso/netsim-topologies/blob/main/multivendor-evpn/test1.1/topology.yml).

Let's check the routing tables on L1, and try a reachability check from H3 (which is connected to L1):

![](t1_1/t1_1_1.png#mid)

![](t1_1/t1_1_2.png#mid)

Also for this test, I created a "netlab validation" [file](https://github.com/ssasso/netsim-topologies/blob/main/multivendor-evpn/test1.1/validate.yml) (which includes also basic tests for the *Test 1* topology):

![](t1_1/t1_1_3.png#mid)


## Test 2

Since it's time to start testing the Fabric using also **MCLAG** (*VLT* or *VSX*), let's take a step back, and try a simple - custom - configuration for LAG, and then MCLAG, on both Dell and Aruba.

I will use some netlab custom config files for this, defining also custom link attributes (and some *plugin* logic).

## Test 2.1

Let's start with a **simple LAG**, with VLANs, between a Dell OS10 device and an Aruba CX.

The topology, with a custom plugin and multiple config templates (one for each device model), can be found [here on github](https://github.com/ssasso/netsim-topologies/tree/main/multivendor-evpn/test2.1).

We are going to create two lags: one with a single VLAN in access mode (`lag 1`), and another with a VLAN Trunk, plus a native VLAN.

As a first step, let's verify the LAG Statuses:

![](t2_1/t2_1_1.png#mid)

![](t2_1/t2_1_2.png#mid)

And then let's try some pings:

![](t2_1/t2_1_3.png#mid)

And this is the ARP table after the pings:

![](t2_1/t2_1_4.png#mid)

ALL LOOKS GOOD!

## Test 2.2

This is similar to Test 2.1... but we are going to introduce MC-LAG!

We do so by introducing other parameters (always defined in our plugin), plus additional settings in the custom templates.

Everything can be found [here on github](https://github.com/ssasso/netsim-topologies/tree/main/multivendor-evpn/test2.2).

![](t2_2/t2_2_1.png#mid)

![](t2_2/t2_2_2.png#mid)

![](t2_2/t2_2_3.png#mid)

![](t2_2/t2_2_4.png#mid)

And, after some pings, we can see our ARP table correctly populated.

![](t2_2/t2_2_5.png#mid)

![](t2_2/t2_2_6.png#mid)

## Test 2.3

As an intermediate step, before working on a real EVPN fabric with MCLAG, let's try a simple **MCLAG + ECMP** routing topology.

We will have an aggregation switch, connected using **Layer 3 only** to the VSX Pair (using ECMP routes, of course). The VSX Pair then it's connected to a Layer 2 peer with a LAG (this is a *classical* topology you can find in all the ArubaCX guides and validated designs - see below).

![](t2_3/arubacx1.png#mid)

**NOTE**: In our *simplified* topology, we call `aggr` the core switch layer of the above picture, and we use only a single switch for that.

But, before doing that, We need to extend our plugin/data model to support a "*Transit VLAN*" between the VSX/VLT switches. Let's also split the plugin code in two parts.

![](t2_3/t2_3_1.png#mid)

![](t2_3/t2_3_2.png#mid)

![](t2_3/t2_3_3.png#mid)


## Test 3

Ok, it's time to add MCLAG to our fabric! For the first test, I decided to try VXLAN only with static flooding.

But, prior to doing so, we need to extend again our plugins/data model to take care of a transit VLAN (between VSX/VLT nodes).

Doing that, I also discovered that Dell and Aruba are using different default OSPF costs for the links.

The most surprising thing is that Dell is using a cost of `4` for a link over a "*ethernet*" inteface, and a cost of `10` for a link over a *vlan*. This means the traffic from a switch to the other will go through the spine(s) first (`4 + 4 = 8`, which is less than `10`).

For that reason, I am setting an **OSPF cost of 10 on all links in the topology**, and forcing an **OSPF cost of 5 on the transit VLAN**.

We also need to expand our plugins/data model to take care of the anycast ip address for the VXLAN VTEP.

Trying to deploy the topology with a first plugin draft (*which simply created an additional loopback, and change all the vxlan config*), I had a bad surprise.

On Dell OS10 it is not possible to change the VTEP source ip address (interface) if there are some VNIs already defined. This is the error returned:
```
nve
    source-interface loopback 1
   % Error: Operation not allowed. Reason:Can't change interface, when Virtual-Network NVE config exists.
```

So, at this point, I [patched netlab again](https://github.com/ipspace/netlab/pull/980) to allow to specify another loopback interface as VXLAN VTEP Source directly on the initial configuration, and then keep the anycast logic on a dedicated local plugin.

The topology data, additional configs and local plugins can be found [here on github](https://github.com/ssasso/netsim-topologies/tree/main/multivendor-evpn/test3).

After the configuration, we can see the anycast VTEP addresses propagated (10.100.20.5, 10.100.20.6):

![](t3/t3_1.png#mid)

And, of course, the basic VXLAN config for VTEP flooding on, for example, *sw1*:

![](t3/t3_2.png#mid)

Now, if we login into *cl1*, we should be able to ping *cl2* but... **WE ARE NOT** :exploding_head:.

IT SEEMS “EVERYTHING” IS BROKEN… We need to deal with the fact that AOS-CX does not support VXLAN+MCLAG.

**I knew this, but I always forget about it**. :face_in_clouds:

## Test 3.1

Since we arrived here at this point, let's *at least* try to see if the templates and plugins I wrote for **Anycast VTEP** are working fine. I will revert the *Test 3* [topology](https://github.com/ssasso/netsim-topologies/tree/main/multivendor-evpn/test3.1) to having a VLT couple and only a single CX switch.

Let's start immediately with a ping from CL1 to CL2:

![](t3_1/t3_1_1.png#mid)

This time it works!

Let's check the VXLAN stuff,

![](t3_1/t3_1_2.png#mid)

and get the MAC Address of CL2 (from CL1):

![](t3_1/t3_1_3.png#small)

Now we can check that the mac address is present on the MAC table of SW1, and it's reachable over VXLAN:

![](t3_1/t3_1_4.png#mid)

**YEAH**. :sunglasses:

Now we only need to wait for the support for MCLAG+VXLAN on ArubaCX Virtual. :monocle_face:

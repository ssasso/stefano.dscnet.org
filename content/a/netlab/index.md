+++
title = "netlab: the swiss knife for network simulations"
date = 2022-04-09
draft = false
tags = ["bgp", "datacenter", "arista", "veos", "cisco", "csr", "mpls", "networking", "ospf", "router", "netsim-tools", "ansible", "netlab", "ipspace"]
categories = []
aliases = [
    "/a/netsim-tools/"
]
+++

> *Edit 2022-08*: *netsim-tools* was renamed to **netlab** on release *1.3*.

> *Edit 2023-06*: new documentation url is [netlab.tools](https://netlab.tools/)

While working on the <u>[VXLAN and EVPN Series]({{< ref "/page/evpnseries" >}} "VXLAN and EVPN Series")</u> I started looking around searching for a good way to automate the configuration of my GNS3 appliances used in the different LABs.

Ansible was a natural choice, since I was already using it for configuring *Dell OS10* and other devices at work.
For that reason, I was thinking about deploying an Ansible instance as a VM (or as a container) on top of GNS3, keeping track of the different *playbooks* using *GIT* (or github), etcetera etcetera etcetera...

But then, I discovered this wonderful tool created by [Ivan Pepelnjak @ ipSpace.net](https://blog.ipspace.net/): **NETLAB** (formerly **NETSIM-TOOLS**).

When I approached it, the first word was: "*Wow!*". A single toolkit to deploy virtual appliances, to configure them, and to manage links and IP address allocations! This would be a dream!

Then I started reading all the docs, having a look at the examples and the existing codebase, ansible playbooks and templates, and more time I spent working with it, more and more I was convinced that this is **the** perfect tool for me.

And the next phase was: let's contribute to it! Let's add some more devices, some more templates, let's make it more useful also for my stuff!

This is why I added support for Mikrotik CHR and VyOS, and their configurations. And this is why, I am sure about that, I will continue to give my little contribution to this wonderful project.

If you are interested in discovering more about *netlab*, have a look at these links:
* [netlab posts on Ivan's Blog](https://blog.ipspace.net/series/netlab.html);
* [netlab official documentation](https://netlab.tools/);
* [netlab github repository](https://github.com/ipspace/netlab).

I promise you will like it! ;)

Creating a topology is as simple as creating a YAML file that describes it, using the *infrastructure-as-code* principle. You can describe nodes, links, and specific parameters:
```
module: [ bgp ]

nodes:
  a:
    bgp.as: 65001
  b:
    bgp.as: 65002
  y:
    bgp.as: 65003
  linux:
    device: linux
    module: []

links: [ a-b, b-y, y-linux ]
```

Going back to the original topic, EVPN support in netlab is still under development, and more other features are to be developed. But [you can contribute](https://netlab.tools/dev/guidelines/) to it, if you wish! ;)

In the meantime, I have a set of additional Ansible templates that you can use to configure an [Arista EOS-based topology](https://github.com/ssasso/netsim-topologies/tree/main/evpn_vxlan_01), and another example for [MLAG](https://github.com/ssasso/netsim-topologies/tree/main/arista_mlag) as well.

On the same [github repository](https://github.com/ssasso/netsim-topologies), you can find additional *netlab* topology examples, like [BGP with Route Reflectors](https://github.com/ssasso/netsim-topologies/tree/main/chr_route_reflector), and [MPLS/LDP L3VPN (VPNv4)](https://github.com/ssasso/netsim-topologies/tree/main/chr_mpls_l3vpn).

Oh! I forgot to say that *netlab* is also able to generate a graph of the topology. See the following example, based on the above YAML file:

![topology](topology_graph.png#small)

Or, a more complex one:

![topology](topology_rr.png#mid)

I hope you will like *netlab* as much as I like it! And I hope to see you soon on the contributor list.

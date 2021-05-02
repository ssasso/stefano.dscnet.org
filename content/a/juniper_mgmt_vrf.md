+++
title = "Juniper Management VRF"
date = 2021-05-01
draft = false
tags = ["vrf", "management", "juniper", "junos", "networking"]
+++

## Management VRF

Personally, I think it's really useful to isolate the OOB Management traffic in a non-default VRF. This will allow to avoid mixing management and non management route tables, and will allow to better control the routing.

Nowadays, almost all the devices allow such configuration.

When I started working with Juniper devices this was not possible, so I had to work with different workarounds; I still remember some MXs with the Full Internet Routing Table in a *routing-instance*, to keep it separated from the default one - used for management.

Luckily, this has changed - and now also JunOS allows you to define a dedicated management routing-instance.

## JunOS configuration for Management VRF

The Management routing-instance has a fixed name that cannot be changed: `mgmt_junos`. The association of the OOB port with this routing-instance is done with a special configuration keyword - so there is no need to specify the interface inside the routing-instance itself.
```
set system management-instance
set interfaces fxp0 unit 0 family inet address 172.23.131.19/24
set routing-instances mgmt_junos routing-options static route 0.0.0.0/0 next-hop 172.23.131.1
```
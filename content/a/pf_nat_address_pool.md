+++
title = "PF nat address pool"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "pf", "firewall"]
+++
In PF (bsd packet filter) il nat address pool viene usato per mascherare in uscita con 2 o più indirizzi:
```
nat on $ext_if inet from any to any -> { 192.0.2.5, 192.0.2.10 }
```
ma per fare in modo che un client venga sempre mappato con lo stesso indirizzo:
```
nat on $ext_if inet from any to any -> 192.0.2.4/31 source-hash
```
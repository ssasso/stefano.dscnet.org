+++
title = "Prevenzione di qualche attacco con Iptables"
date = 2007-12-30
draft = false
tags = ["firewall", "iptables", "netfilter", "linux"]
+++

**Protezione Syn-flood:**
```bash
iptables -A FORWARD -p tcp --syn -m limit --limit 1/s -j ACCEPT
```

**Protezione port scanning:**
```bash
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST \ 
  -m limit --limit 1/s -j ACCEPT
```

**Protezione ping of death:**
```bash
iptables -A FORWARD -p icmp --icmp-type echo-request \
  -m limit --limit 1/s -j ACCEPT
```
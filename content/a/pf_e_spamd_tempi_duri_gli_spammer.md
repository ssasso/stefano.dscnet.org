+++
title = "PF e spamd: tempi duri per gli spammer"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "pf", "firewall", "spamd", "antispam"]
+++
aggiungiamo queste regole a pf:
```
table <spamd> persist
table <spamd-white> persist file "/var/mail/whitelist.txt"
rdr pass on $ext_if inet proto tcp from <spamd> to \
         { $ext_if, $int_if:network } port smtp -> 127.0.0.1 port 8025
rdr pass on $ext_if inet proto tcp from !<spamd-white> to \
         { $ext_if, $int_if:network } port smtp -> 127.0.0.1 port 8025
```
e modifichiamo il file di configurazione di **spamd** secondo i nostri gusti (*spamd.conf*).
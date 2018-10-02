+++
title = "PF e Squid trasparente"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "pf", "firewall", "squid", "proxy"]
+++
Le modifiche da fare al file di configurazione di **squid** sono minime:
```
http_port 127.0.0.1:3128
http_access deny to_localhost
acl our_networks src 10.0.0.0/8
http_access allow our_networks
visible_hostname proxy.mynet.org
httpd_accel_host virtual
httpd_accel_port 80
httpd_accel_with_proxy on
httpd_accel_uses_host_header on
```
mentre, per quanto riguarda **pf**:
```
rdr on $int_if inet proto tcp from any to any port www -> 127.0.0.1 port 3128
pass in on $int_if inet proto tcp from any to 127.0.0.1 port 3128 keep state
pass out on $ext_if inet proto tcp from any to any port www keep state
```

**Attenzione!**

**squid** cerca di aprire */dev/pf* per interrogare il packet filter. è necessario quindi assegnare i corretti permessi:
```bash
chgrp _squid /dev/pf
chmod g+rw /dev/pf
```
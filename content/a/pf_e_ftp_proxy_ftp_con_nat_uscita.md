+++
title = "pf e ftp-proxy, ftp con nat in uscita"
date = 2007-12-11
draft = false
tags = ["openbsd", "bsd", "pf", "firewall", "nat", "proxy"]
+++
**ftp-proxy** può esserci utile se abbiamo una rete nattata che deve accedere a server ftp sparsi in giro per il mondo, senza sapere precisamente quali siano i loro ip.

inseriamo quindi una riga in */etc/inetd.conf* per far partire **ftp-proxy** in modalità "nat"
```
127.0.0.1:8021 stream tcp nowait root /usr/libexec/ftp-proxy ftp-proxy -n
```
riavviamo quindi inetd
```bash
kill -HUP `cat /var/run/inetd.pid` 
```
inseriamo quindi una regola *rdr* in **pf**, subito dopo le regole di *nat*:
```
rdr on $int_if proto tcp from any to any port ftp -> 127.0.0.1 port 8021
```
in più, il traffico ftp attivo deve essere lasciato passare verso il nostro firewall, su cui sarà in ascolto **ftp-proxy**
```
pass in on $ext_if inet proto tcp from port ftp-data to ($ext_if) \
    user proxy flags S/SA keep state
```
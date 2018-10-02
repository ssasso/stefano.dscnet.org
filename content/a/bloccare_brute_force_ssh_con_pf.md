+++
title = "Bloccare brute force ssh con pf"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "pf", "firewall"]
+++
Per lasciar passare le connessioni ssh, **pf** dovrebbe avere una regola simile a questa:
```
pass in quick on $external inet proto tcp from any to any port ssh flags S/SA keep state
```
per bloccare i bruteforce è sufficiente modificarla in:
```
table <ssh-bruteforce> persist
block in quick from <ssh-bruteforce>
pass in quick on $external inet proto tcp from any to any port ssh flags S/SA keep state \
  ( max-src-conn-rate 2/10, overload <ssh-bruteforce> flush global)
  ```
che, nell'ordine:

* definisce una tabella per conservare gli ip degli attaccanti
* blocca tutte le connessioni provenienti da tali ip
* autorizza le connessioni ssh, ma che siano al massimo 2 tentativi di connessione in 10 secondi, altrimenti registra l'ip nella tabella prima definita, e distrugge tutte le connessioni relative a tale ip

Ci sarà anche da implementare un cron job che ogni tanto dia una ripulita alla tabella `<ssh-bruteforce>`.
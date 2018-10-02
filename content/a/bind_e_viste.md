+++
title = "BIND e viste"
date = 2007-12-08
draft = false
tags = ["bind", "dns"]
+++
Ecco come fornire informazioni diverse con bind, a seconda del client che ha effettuato la richiesta.

Questo sistema può essere utile nel caso dei server siano dietro un NAT e abbiano un indirizzo diverso a seconda della rete in cui si trova il client.

modiﬁchiamo *named.conf*:
```
acl "internal" {
   127/8;
   192.168.3/24;
};
view "internal" {
   match-clients { "internal" };
   recursion yes; # abilita il lookup verso internet
   zone "azienda.it" {
      type     master;
      file    "master/azienda.it.locale";
   };
};
view "internet" {
   match-clients { any; }
   recursion no;
   zone "azienda.it" {
      type     master;
      file    "master/azienda.it.internet"; 
   };
};
```
il file *azienda.it.locale* conterrà:
```
$TTL 3h
@ IN SOA ns1.azienda.it. root.azienda.it. (
     2007070701 ; serial
     3h    ; refresh after 3 hours
     1h    ; retry after 1 hour
     1w    ; expire after 1 week
     1h ) ; negative caching ttl of 1 hour
  IN NS     ns1.azienda.it.
  IN NS     ns2.azienda.it.
  IN MX     10 mx1.azienda.it.
  IN MX     20 mx2.azienda.it.
  IN A      192.168.3.210
localhost IN A 127.0.0.1
mx1    IN A 192.168.3.220
mx2    IN A 192.168.3.221
ns1    IN A 192.168.3.201
ns2    IN A 192.168.3.202
www    IN A 192.168.3.210
```
mentre il file *azienda.it.internet*:
```
$TTL 3h
@ IN SOA ns1.azienda.it. root.azienda.it. (
     2007070701 ; serial
     3h    ; refresh after 3 hours
     1h    ; retry after 1 hour
     1w    ; expire after 1 week
     1h ) ; negative caching ttl of 1 hour
  IN NS     ns1.azienda.it.
  IN NS     ns2.azienda.it.
  IN MX     10 mx1.azienda.it.
  IN MX     20 mx2.azienda.it.
  IN A      62.199.223.12
localhost IN A 127.0.0.1
mx1    IN A 62.199.223.13
mx2    IN A 62.199.223.14
ns1    IN A 62.199.223.12
ns2    IN A 62.199.223.10
www    IN A 62.199.223.12
```
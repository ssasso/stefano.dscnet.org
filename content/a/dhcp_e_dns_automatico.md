+++
title = "DHCP e DNS automatico"
date = 2007-12-08
draft = false
tags = ["bind", "dns", "dhcp"]
+++
Vediamo come impostare un sistema di **dhcp** e **dns** automatico, in modo che quando il server dhcp rilascia un indirizzo, automaticamente venga aggiornato il nostro server dns.

rimuoviamo le vecchie versioni, e installiamo le nuove
```bash
apt-get remove --purge dhcp bind
apt-get install bind9 dhcp3-server
```
modifichiamo il file di configurazione principale di bind, *named.conf*:
```
controls {
   inet 127.0.0.1 allow { localhost; } keys { "rndc-key"; };
};
include "/etc/bind/rndc.key";
```
il file *rndc.key* deve essere incluso sia da **bind** che da **dhcpd**, e contiene
```
key "rndc-key" {
   algorithm  hmac-md5;
   secret	  "lgkbhjhtthgtlghtl6567==";
};
```
ovviamente la chiave deve essere rigenerata!

e poi, nel file che definisce le zone, *named.conf.local*:
```
zone "rete.lan" {
   type master;
   file "/etc/bind/db.rete";
   allow-update { key "rndc-key"; };
   notify yes;
};
zone "0.168.192.in-addr.arpa" {
   type master;
   file "/etc/bind/db.192.168.0";
   allow-update { key "rndc-key"; };
   notify yes;
};
```
(i file di zona sono standard, non li vediamo nel dettaglio)

per quanto riguarda **dhcpd**, il file di configurazione *dhcpd.conf* deve somigliare a:
```
server-identifier  my-server-name;
ddns-update-style  interim;
ignore             client-updates;
include            "/etc/bind/rndc.key";
authoritative;
subnet 192.168.0.0 netmask 255.255.255.0 {
   option routers             192.168.0.254;
   option subnet-mask         255.255.255.0;
   option domain-name         "rete.lan";
   option domain-name-servers 192.168.0.254;
   option ntp-servers         192.168.0.254;
   ddns-updates on;
   ddns-domainname "rete.lan";
   ddns-rev-domainname "in-addr.arpa";
   zone rete.lan. {
      primary 192.168.0.254;
      key rndc-key;
   }
   zone 0.168.192.in-addr.arpa. {
      primary 192.168.0.254;
      key rndc-key;
   }
   default-lease-time 21600;
   max-lease-time	  43200;
   allow		unknown-clients;
   range		192.168.0.1 192.168.0.150;
}
```
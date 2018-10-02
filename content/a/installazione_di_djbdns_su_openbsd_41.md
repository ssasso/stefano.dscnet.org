+++
title = "Installazione di djbdns su OpenBSD 4.1"
date = 2007-12-14
draft = false
tags = ["bsd", "openbsd", "djbdns", "dns"]
+++
### Si presuppone un minimo di conoscenza di djbdns.

Partiamo con l'installazione di **ucspi-tcp** e dei **daemontools**:
```bash
cd /tmp
wget http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz
tar xzf ucspi-tcp-0.88.tar.gz
(cd ucspi-tcp-0.88 && make setup check)
wget http://cr.yp.to/daemontools/daemontools-0.76.tar.gz
mkdir -p /package
cd /package
tar xzf /tmp/daemontools-0.76.tar.gz
(cd admin/daemontools-0.76 && package/install && rm -r compile)
rm /tmp/daemontools-0.76.tar.gz
rm -r /tmp/ucspi-tcp-0.88*
```
riavviamo quindi il sistema per far partire i daemontools.
Se però non vogliamo riavviare, basta andare a vedere cosa è stato scritto in */etc/rc.local* dall'installazione dei daemontools, e lanciarlo :-)

installiamo ora **djbdns**:
```bash
cd /tmp
wget http://cr.yp.to/djbdns/djbdns-1.05.tar.gz
tar xzf djbdns-1.05.tar.gz
(cd djbdns-1.05 && make setup check)
rm -r /tmp/djbdns-*
useradd -s /usr/bin/true -d /nonexistent -u 901 Gdnscache
useradd -s /usr/bin/true -d /nonexistent -u 902 Gtinydns
useradd -s /usr/bin/true -d /nonexistent -u 903 Gdnslog
mkdir -p /etc/service
```

Vediamo ora, a partire da un'installazione **djbdns** standard, come attivare una cache dns
```bash
dnscache-conf Gdnscache Gdnslog /etc/service/dnscache 192.168.171.11
touch /etc/service/dnscache/root/ip/192.168.171
ln -s /etc/service/dnscache /service/
```
dove *192.168.171.11* è l'indirizzo ip con cui la nostra cache deve rimanere in ascolto.

Nella seconda riga, *192.168.171* significa che la cache può essere interrogata da tutti gli ip che iniziano per *192.168.171*.

È possibile creare altri file per consentire ad ulteriori reti di interrogare la nostra cache.

Et voilà, la cache è servita.

Vediamo ora, a partire da un'installazione **djbdns** standard, come attivare un dns autoritativo per i nostri domini:
```bash
tinydns-conf Gtinydns Gdnslog /etc/service/tinydns 192.168.171.52
ln -s /etc/service/tinydns /service/
```
dove *192.168.171.52* è l'indirizzo ip a cui il server dns deve rispondere.

**Attenzione!** se **tinydns** gira su una macchina in cui gira già **dnscache**, **tinydns** e **dnscache** non possono restare in ascolto sullo stesso ip!

Per motivi di sicurezza è comunque sconsigliato far girare sia **tinydns** che **dnscache** sulla stessa macchina.
Se vogliamo che **dnscache* interroghi direttamente **tinydns** (per i domini del quale è autoritativo) senza passare per i root servers, in */etc/service/dnscache/root/servers* diamo
```bash
echo 192.168.171.52 > gnustile.local
echo 192.168.171.52 > 171.168.192.in-addr.arpa
```
dove *192.168.171.52* è l'indirizzo di **tinydns*, e *gnustile.local* è il nostro dominio.

dobbiamo quindi riavviare **dnscache** con
```bash
svc -t /etc/service/dnscache
```

configuriamo ora **tinydns** per gestire il nostro dominio; editiamo */etc/service/tinydns/root/data* inserendo
```
# dns autoritativo (anche per la zona inversa)
.gnustile.local:192.168.171.52:a
.gnustile.local:192.168.171.11:b
.gnustile.local:192.168.171.24:c
.171.168.192.in-addr.arpa:192.168.171.52:a
.171.168.192.in-addr.arpa:192.168.171.11:b
.171.168.192.in-addr.arpa:192.168.171.24:c
# record MX
@gnustile.local:192.168.171.22:a
@gnustile.local:192.168.171.23:b
# record A
=gandalf.gnustile.local:192.168.171.1
=illo.gnustile.local:192.168.171.11
=groucho.gnustile.local:192.168.171.21
=chico.gnustile.local:192.168.171.22
=harpo.gnustile.local:192.168.171.23
=gummo.gnustile.local:192.168.171.24
=zeppo.gnustile.local:192.168.171.25
# alias
+mail.gnustile.local:192.168.171.22
+www.gnustile.local:192.168.171.21
+www.gnustile.local:192.168.171.24
+mailout.gnustile.local:192.168.171.25
```
Dopo aver salvato, diamo
```bash
cd /etc/service/tinydns/root 
make
```
Questo make "compilerà" il file *data.cdb*, che sarà il file che **tinydns** leggerà.

In alternativa alle modifiche manuali possiamo usare alcuni script presenti nella cartella, come

> add-ns

> add-host

> add-mx

Può essere utile, in **tinydns**, fornire indirizzi diversi a seconda del client che effettua la richiesta:
è sufficiente modificare il file data, inserendone all'inizio
```
%in:192.168.171
%ex
```
e poi, nel contenuto
```
=www.dominio.it:192.168.171.72:::in
=www.dominio.it:194.177.96.1:::ex
```
per tutto il resto si rimanda alle ottime guide presenti in rete; tanto per citarne una 

<a href="http://www.morettoni.net/docs/djbdns.html" target="_BLANK">djbdns - Un'alternativa (sicura) a BIND</a>
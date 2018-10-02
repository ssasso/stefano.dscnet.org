+++
title = "Homemade Dynamic DNS"
date = 2007-12-14
draft = false
tags = ["bind", "dns"]
+++
Vediamo come "costruirci" in casa un servizio tipo no-ip o dyndns usando usando nsupdate e le chiavi dns.

Iniziamo generando la chiave che useremo per l'aggiornamento:
```bash
dnssec-keygen -a HMAC-MD5 -b 512 -n USER stefano.dyna.gnustile.net.
```
Verranno create 2 chiavi, una pubblica (da usare sul server) e una privata.

Il comando da lanciare, per aggiornare il dns sarà
```bash
nsupdate -k Kstefano.dyna.gnustile.net.+157+09585.private -v file.diffs
```
dove *file.diffs* conterrà
```
server ns1.gnustile.net
zone dyna.gnustile.net
update delete stefano-local.dyna.gnustile.net. A
update add stefano-local.dyna.gnustile.net. 86400 A 141.x.y.z
show
send
```
Nel server, creiamo il file */etc/bind/keys.conf*, che includeremo da named.conf con
```
include "keys.conf";
```
con il contenuto
```
key stefano.dyna.gnustile.net. {
  algorithm HMAC-MD5;
  secret "YrVW9yP6gNMA7VbcU/r2mSIwYnFj/XkCDd6QuqOHE26/ipnrPy+eXrKrUyaFhB2XWNdVLUX7QCUkfhg4zN5YiA==";
};
```
recuperando ovviamente il secret dalla nostra chiave pubblica.

modifichiamo quindi la definizione della nostra zona in
```
zone  "dyna.gnustile.net" {
        type master;
        file  "dyna.gnustile.net.zone";
        allow-update {
                key stefano.dyna.gnustile.net.;
        };
};
```
volendo possiamo anche dare un accesso parziale alla zona, con
```
zone  "dyna.gnustile.net" {
        type master;
        file  "dyna.gnustile.net.zone";
        update-policy {
           grant user123.dyna.gnustile.net. name user123.dyna.gnustile.net. A TXT;
           grant stefano.dyna.gnustile.net. subdomain dyna.gnustile.net. ANY;
        };
};
```
in generale, la sintassi di `grant` è
```
grant <key> <type> <zone> <record-types>;
```
**Attenzione!!** una volta che le modifiche dinamiche avranno effetto, verrà creato il file *dyna.gnustile.net.zone.jnl*.

Se volessimo fare qualche modifica al nostro file di zona, sarà necessario interrompere gli aggiornamenti con
```bash
rndc freeze $ZONE
```
modificare il file, controllarlo con `named-checkzone` e poi lanciare
```bash
rndc thaw $ZONE
```
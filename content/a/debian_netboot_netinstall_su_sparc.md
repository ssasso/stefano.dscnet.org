+++
title = "Debian netboot/netinstall su Sparc"
date = 2008-06-08
draft = false
tags = ["openboot", "sparc", "debian", "netboot", "netinstall", "linux"]
+++
*(grazie a Manichen per alcuni spunti)*

Per prima cosa è necessario conoscere il MAC address della scheda di rete del nostro sparc. E' visibile nel "banner" di **OpenBoot**.

Passiamo ora alla configurazione del nostro install server: sono necessari un server **rarp** e **tftp**:
```bash
apt-get install rarpd tftpd-hpa
```

inseriamo quindi il MAC address della macchina nel file di configurazione di **rarpd**: */etc/ethers*
```
08:00:20:XX:YY:ZZ 192.168.1.2
```
(*192.168.1.2* è l'indirizzo che verrà assegnato alla nostra macchina sparc)

riavviamo quindi **rarpd** con
```bash
/etc/init.d/rarpd restart
```

Una volta ricevuto un indirizzo IP, OpenBoot cercherà un'immagine da cui bootare nel server tftp: l'immagine deve chiamarsi come l'indirizzo IP della macchina in notazione esadecimale.
Per effettuare la conversione usiamo **printf**:
```bash
$ printf "%.2X%.2X%.2X%.2X\n" 192 168 1 2
```
L'output sarà qualcosa del tipo:

> C0A80102

Scarichiamo quindi l'immagine di netinstall di debian, e creiamo un link simbolico a essa con questo nome:
```bash
cd /var/lib/tftpboot
wget http://ftp.it.debian.org/debian/dists/etch/main/installer-sparc/current/images/sparc64/netboot/2.6/boot.img
ln -s boot.img C0A80102
```
Possiamo quindi far partire il nostro sparc, premere Stop-A per mostrare il prompt di OpenBoot:

> ok 

e digitare
```
boot net
```

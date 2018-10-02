+++
title = "PF: server ftp dietro nat con ftp-proxy"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "pf", "firewall", "ftp", "nat"]
+++
Questo appunto ho lo scopo di spiegare in breve il processo di configurazione per il nuovo **ftp-proxy** incluso dalla release 3.9 di OpenBSD.

L'uso del proxy-ftp puo' essere evitato se il demone (vsftpd, ftpzilla-server) che andiamo a pubblicare permette di impostare l'ip di risposta passiva.

Nei maledetti server IIS questo non è possibile quindi si è costretti ad usare ftp-proxy.

Il seguente *pf.conf* mostra le regole essenziali per pubblicare il server ftp in una DMZ con nat/port forwarding.
```
ext_if="sis0"
fw_ext_ip="xxx.xxx.xxx.xx2"
web1_ext_ip="xxx.xxx.xxx.xx3"
web1_dmz_ip="yyy.yyy.yyy.yy3"
web1_in_tcp="21, 80, 443, > 49000"
scrub in
nat-anchor "ftp-proxy/*"
rdr-anchor "ftp-proxy/*"
rdr on $ext_if inet proto tcp from any to $web1_ext_ip port 21 ->  127.0.0.1 port 8022
binat on $ext_if inet from $web1_dmz_ip to any -> $web1_ext_ip
anchor "ftp-proxy/*"
block in on $ext_if
pass in on $ext_if proto tcp from any to $web1_ext_ip port $web1_in_tcp keep state
pass out keep state
```
A questo punto modifichiamo *rc.local* per avviare il proxy ftp all'avvio.
Come parametro di **ftp-proxy** inseriamo l'ip del nostro server in dmz.
Per la fase di test è meglio indicare anche l'opzione `-D6` per aumentare il dettaglio del logging
```bash
echo "/usr/libexec/ftp-proxy -D6  -R <web1_dmz_ip> -p 8022" >> /etc/rc.local
```
Se ci sono diversi server ftp da plubblicare bisogna cambire la porta locale di ascolto e l'ip del server interno.
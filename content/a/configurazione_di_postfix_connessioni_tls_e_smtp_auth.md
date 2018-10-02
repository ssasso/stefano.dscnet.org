+++
title = "Configurazione di postfix per connessioni TLS e SMTP-AUTH"
date = 2007-12-13
draft = false
tags = ["postfix", "mta"]
+++
I server smtp mailout di libero (mio provider) hanno cominciato a dare i numeri, e io mi sono stufato.
Ho finalmente deciso di configurare uno dei server postfix che gestisco per fare il relay delle mail con autenticazione smtp, e visto che c'ero l'ho configurato anche per accettare connessioni TLS.

ho quindi dato:
```bash
apt-get install postfix-tls sasl2-bin libsasl2 libsasl2-modules
```
dopodichè ho modificato */etc/default/saslauthd* decommentando la riga
```
START=yes
```
e modificando la variabile `MECHANISMS` in
```
MECHANISMS="sasldb"
```
in quanto volevo che gli utenti dell'smtp-auth fossero completamente separati sia dagli account di sistema che dagli account pop3/imap.
Ho quindi creato */etc/postfix/sasl/smtpd.conf* con al suo interno
```
pwcheck_method: saslauthd
mech_list: plain login
```
e nella configurazione di postfix ho inserito
```
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
broken_sasl_auth_clients = yes
```
sempre nella configurazione di postfix, ho modificato `smtpd_client_restrictions` in modo da avere
```
smtpd_client_restrictions = permit_mynetworks,
        hash:/etc/postfix/white_access,
        permit_sasl_authenticated,
        ...
```
e `smtpd_recipient_restrictions` in modo da avere
```
smtpd_recipient_restrictions = permit_mynetworks,
        permit_sasl_authenticated,
        reject_unauth_destination,
        ...
```
per fare in modo che postfix, dal suo chroot, riuscisse a comunicare con saslauthd ho dato
```bash
rm -r /var/run/saslauthd/
mkdir -p /var/spool/postfix/var/run/saslauthd
ln -s /var/spool/postfix/var/run/saslauthd /var/run
chgrp sasl /var/spool/postfix/var/run/saslauthd
adduser postfix sasl
```
poi ho riavviato i due servizi
```bash
/etc/init.d/postfix restart
/etc/init.d/saslauthd start
```
ho quindi aggiunto un utente al database sasl:
```bash
saslpasswd2 -c stefano
```
e ho testato il tutto:
```
$ perl -MMIME::Base64 -e 'print encode_base64("stefano\0stefano\0miapassword");'
c3RlZmFubwBzdGVmYW5vAG1pYXBhc3N3b3Jk
$ telnet 127.0.0.1 25
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
220 mioserver ESMTP Postfix (Debian/GNU)
EHLO io
250-mioserver
250-PIPELINING
250-SIZE 10240000
250-ETRN
250-STARTTLS
250-AUTH LOGIN PLAIN
250-AUTH=LOGIN PLAIN
250 8BITMIME
AUTH PLAIN c3RlZmFubwBzdGVmYW5vAG1pYXBhc3N3b3Jk
535 Error: authentication failed
235 Authentication successful
```
**perfetto!**

passiamo quindi alla configurazione di postfix tls; per prima cosa creiamo il certificato
```bash
openssl req -new -outform PEM -out /etc/postfix/smtpd.cert -newkey rsa:2048 \
    -nodes -keyout /etc/postfix/smtpd.key -keyform PEM -days 3650 -x509
chown root:postfix /etc/postfix/smtpd.key
chmod 640 /etc/postfix/smtpd.key
```
e inseriamo in *main.cf*:
```
smtpd_use_tls = yes
smtpd_tls_cert_file = /etc/postfix/smtpd.cert
smtpd_tls_key_file = /etc/postfix/smtpd.key
```
riavviamo postfix... e il gioco è fatto!
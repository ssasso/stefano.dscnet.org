+++
title = "Configurazione di Postfix per usare un relayhost che richiede autenticazione e connessione TLS"
date = 2007-12-13
draft = false
tags = ["postfix", "mta"]
+++
Ecco come ho configurato il mio postfix locale per mandare le mail tramite un relayhost con connessione tls e autenticazione smtp:

*main.cf*:
```
myorigin = gnustile.local
smtpd_banner = $myhostname ESMTP
biff = no
append_dot_mydomain = no
myhostname = gandalf.gnustile.local
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = localhost, localhost.localdomain, gandalf, gnustile.local, gandalf.gnustile.local
mynetworks = 127.0.0.0/8
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = all
smtp_generic_maps = hash:/etc/postfix/generic
smtp_tls_loglevel = 1
smtp_enforce_tls = yes
smtp_tls_per_site = hash:/etc/postfix/tls_per_site
smtp_use_tls = yes
smtpd_sasl_auth_enable = no
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtpd_sasl_local_domain = gnustile.local
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
relayhost = [mio.mailout.server]
disable_dns_lookups = yes
smtp_tls_cert_file =
smtp_tls_dcert_file =
smtp_tls_key_file =
smtp_tls_dkey_file =
```
*/etc/postfix/generic*:
```
@gnustile.local utente@dominioreale.it
@gandalf.gnustile.local utente@dominioreale.it
```
*/etc/postfix/tls_per_site*:
```
mio.mailout.server MUST_NOPEERMATCH
```
*/etc/postfix/sasl_passwd*:
```
mio.mailout.server myusername:mypassword
```
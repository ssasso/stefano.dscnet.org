+++
title = "OpenLDAP e SSL (ldaps)"
date = 2007-12-08
draft = false
tags = ["ldap", "ssl", "ldaps", "openldap", "openssl"]
+++
eseguiamo:
```bash
sudo mkdir /etc/ldap/ssl
cd /etc/ldap/ssl
sudo openssl req -newkey rsa:1024 -x509 -nodes -out server.pem -keyout server.pem -days 3650
```
nel file */etc/ldap/slapd.conf* inseriamo:
```
TLSCipherSuite HIGH:MEDIUM:-SSLv2
TLSCACertificateFile /etc/ldap/ssl/server.pem
TLSCertificateFile /etc/ldap/ssl/server.pem
TLSCertificateKeyFile /etc/ldap/ssl/server.pem
```
nel file */etc/default/slapd* decommentiamo la riga
```
SLAPD_SERVICES="ldap://127.0.0.1:389/ ldaps:/// ldapi:///"
```
modifichiamo il file */etc/ldap/ldap.conf* facendolo diventare simile a questo:
```
BASE dc=dominio,dc=com
URI ldaps://ldap.dominio.com/
TLS_REQCERT allow
```
+++
title = "Sistema di Single Sign-On: Samba PDC con LDAP e Kerberos"
date = 2009-04-16
draft = false
tags = ["autenticazione", "kerberos", "ldap", "openldap", "samba", "sasl", "single sign-on"]
+++

Vista la mancanza di HOWTO esaustivi sull'argomento dell'integrazione di **Samba** con **LDAP** e **Kerberos** per realizzare una soluzione di Single Sign-On per reti miste Windows/Unix, 
ho preso spunto da una guida in portoghese e ho realizzato un HOWTO in italiano.

[La trovate qui](/howto/samba-pdc-ldap-kerberos/).

Vedremo in questa guida come creare un PDC Samba che sia anche un KDC Kerberos e che abbia le informazioni sugli utenti salvate in un albero LDAP.

Le istruzioni si riferiranno a Ubuntu Server 8.04LTS ma possono essere applicate a qualsiasi distribuzione.

Con questa guida sarà possibile integrare l'autenticazione di macchine Windows e Unix in un ambiente misto. Il server configurato fornirà quindi le informazioni di autenticazione e autorizzazione per entrambi i sistemi.

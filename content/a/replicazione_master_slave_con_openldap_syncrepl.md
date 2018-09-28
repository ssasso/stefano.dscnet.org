+++
title = "Replicazione master-slave con OpenLDAP (syncrepl)"
date = 2009-07-30
draft = false
tags = ["replica", "linux", "ldap", "openldap", "syncrepl"]
+++

La cosa è abbastanza semplice da realizzare: per la sincronizzazione vera e propria verrà utilizzato l'overlay syncprov, 
mentre per far si che le modifiche richieste allo slave siano effettuate sul master verrà utilizzato l'overlay chain.

**MASTER**:

* decommentare la direttiva rootdn, questa è infatti necessaria a syncrepl
* aggiungere alla configurazione:

```
moduleload syncprov
index entryCSN,entryUUID eq
overlay syncprov
syncprov-checkpoint 100 10
syncprov-sessionlog 200
```

**SLAVE**:

* decommentare la direttiva rootdn, questa è infatti necessaria a syncrepl
* aggiungere alla configurazione:

```
moduleload syncprov
moduleload back_ldap

overlay              chain
chain-uri            ldap://vps-5.vznet.lan/
chain-idassert-bind  bindmethod="simple"
                     binddn="cn=admin,dc=vznet,dc=lan"
                     credentials="admin123"
                     mode="self"
```

* aggiungere alla fine della configurazione esistente:

```
overlay syncprov
syncrepl  rid=001
          provider=ldap://vps-5.vznet.lan:389
          type=refreshAndPersist
          searchbase="dc=vznet,dc=lan"
          filter="(objectClass=*)"
          scope=sub
          schemachecking=off
          bindmethod=simple
          binddn="cn=admin,dc=vznet,dc=lan"
          credentials=admin123
updateref ldap://vps-5.vznet.lan/
```

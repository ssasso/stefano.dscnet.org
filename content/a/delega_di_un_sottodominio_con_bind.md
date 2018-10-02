+++
title = "Delega di un sottodominio con BIND"
date = 2007-12-12
draft = false
tags = ["dns", "bind"]
+++
Ipotizziamo di avere il dominio **dominio.it**, e vogliamo delegare la gestione di **sotto.dominio.it** ad un altro nameserver (in questo esempio *ns3.dominio.it*).

nel file di zona del dns autoritativo per **dominio.it** inseriamo
```
sotto     IN     NS      ns3.dominio.it.
sotto     IN     TXT     "delega sottodominio"
```
mentre il file di zona di **sotto.dominio.it** avrà una configurazione standard.
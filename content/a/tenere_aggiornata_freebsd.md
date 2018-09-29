+++
title = "Tenere aggiornata FreeBSD"
date = 2008-10-06
draft = false
tags = ["bsd", "freebsd", "ports"]
+++
Vediamo come tenere aggiornati i pacchetti/ports di un sistema FreeBSD:

per cominciare è necessario installare il pacchetto/port **portmanager**:
```bash
cd /usr/ports/ports-mgmt/portmanager
make all install
```
poi utilizziamo **portsnap** per recuperare le ultime informazioni sui port:
```bash
portsnap fetch
```
e, solo la prima volta, eseguiamo:
```bash
portsnap extract
```
le successive volte per aggiornare la directory dei ports è sufficiente
```bash
portsnap fetch
portsnap update
```
Successivamente, per aggiornare i ports/package installati
```bash
portmanager -u
```
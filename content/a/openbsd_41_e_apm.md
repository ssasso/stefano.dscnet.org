+++
title = "OpenBSD 4.1 e apm"
date = 2007-12-18
draft = false
tags = ["openbsd", "bsd", "apm"]
+++
Ho installato OpenBSD 4.1 su hotdog. Dopo varie peripezie ora OpenBSD gira egregiamente.

Se non sai chi è hotdog, dai un'occhiata alla pagina hardware :)

Non essendo hotdog dotato di lettore cd, ed avendo una scheda di rete PCMCIA, ho dovuto utilizzare **floppyC41.fs**;
peccato però che il kernel andava in panic a causa dell'apm. Ho dovuto quindi disabilitarlo nel kernel. Ecco come ho fatto:

Al boot prompt,

> boot>

ho inserito
```
boot> boot -c
```
in modo da lanciare lo "User-Mode Kernel Configurator", e una volta avviato ho digitato
```
UKC> disable apm
UKC> quit
```

e poi, finalmente, tutto è partito correttamente. Sono riuscito a fare un'installazione quasi minimale
(**bsd**, **bsd.rd**, **base41**, **etc41**, **man41**; si, lo so, potevo fare a meno di usare **man41**) e hotdog è risultato "idoneo" (aka: ha completato correttamente l'installazione :))

Non avendo voglia di usare l'User-Mode Kernel Configurator per disabilitare a mano l'apm ad ogni accensione, 
e non avendo voglia di ricompilare il kernel, ho configurato il kernel di default per avere di default apm disabilitato.

Ho lanciato
```
# config -ef /bsd
UKC> disable apm
UKC> quit
```
ed il gioco è fatto. 
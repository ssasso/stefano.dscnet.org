+++
title = "FreeBSD: prompt user-friendly per csh"
date = 2008-10-06
draft = false
tags = ["bsd", "freebsd", "csh", "shell"]
+++
Per rendere più piacevole il prompt standard di **csh** su freebsd è sufficiente modificare il file *~/.login* aggiungendo:
```bash
set prompt="%B[%n@%m]%b%/: "
```
Si avrà quindi un prompt del tipo

> [root@balin]/root: 
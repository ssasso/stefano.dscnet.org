+++
title = "OpenBSD unofficial iso"
date = 2007-12-08
draft = false
tags = ["bsd", "openbsd", "iso"]
+++
Ecco i passaggi per realizzare un'immagine iso non ufficiale del cd di installazione di openbsd:
```bash
wget -c -r -np ftp://spargel.kd85.com/pub/OpenBSD/4.2/i386
cp -a spargel.kd85.com/pub/OpenBSD/4.2 .
cp 4.2/i386/cd42.iso OpenBSD-unofficial-4.2.iso
growisofs -M OpenBSD-unofficial-4.2.iso -R -iso-level 3 -graft-points 4.2=4.2
```
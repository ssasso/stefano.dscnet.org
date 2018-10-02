+++
title = "Riconoscimento di volumi LVM"
date = 2007-12-07
draft = false
tags = ["linux", "lvm"]
+++
E se da una distribuzione live che non effettua automaticamente il riconoscimento di volumi LVM2 avessimo bisogno di accedere ai dati contenuti in tali volumi?

Semplice, i passi da fare sono veramente pochi :-)

##### scansionare i dischi alla ricerca di volumi fisici LVM (partizioni LVM)
```bash
pvscan
```
##### scansionare i volumi fisici alla ricerca di gruppi di volumi (Volume Group)
```bash
vgscan
```
##### attiviamo ora i vg trovati:
```bash
vgchange -a y
```
##### possiamo quindi visualizzare le informazioni sui vg:
```bash
vgdisplay
```
##### scansioniamo ora i vg alla ricerca di volumi logici (lv)
```bash
lvscan
```
##### possiamo vedere lo stato con
```bash
lvdisplay
```
##### infine possiamo montare il nostro volume 
```bash
man mount
```
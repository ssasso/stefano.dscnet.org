+++
title = "SPARC OpenBoot Password Reset"
date = 2008-06-08
draft = false
tags = ["openboot", "sparc"]
+++
Ebbene si, in casa c'è un nuovo computer... un "nuovo" mitico **Sparc Ultra 10**.

Ho dovuto metterci un disco nuovo (me l'han dato senza);
al momento dell'installazione ho scoperto che era stata impostata una password per l'openboot, e che questo consentiva solo il boot da disco o da rete.

Una volta [installata Debian via rete](/a/debian_netboot_netinstall_su_sparc/), per sistemare la questione password, è bastato lanciare il comando
```bash
eeprom security-mode=none
```
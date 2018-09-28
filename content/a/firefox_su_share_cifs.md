+++
title = "Firefox su share CIFS"
date = 2009-07-30
draft = false
tags = ["linux", "brl", "cifs", "firefox", "samba", "smb", "sqlite"]
+++
Firefox salva i suoi dati su un database Sqlite3.

Sqlite però usa il locking di area di byte (*bit range lock*), e CIFS si ingrippa.
Tuttavia questo è un problema solo di client linux, su win va tutto.

per risolvere il problema basta usare il parametro *nobrl* di **mount.cifs**

dalla man page:

> **nobrl**

> Do not send byte range lock requests to the server. This is
> necessary for certain applications that break with cifs style
> mandatory byte range locks (and most cifs servers do not yet
> support requesting advisory byte range locks).

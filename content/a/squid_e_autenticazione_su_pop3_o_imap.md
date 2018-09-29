+++
title = "Squid e autenticazione su POP3 o IMAP"
date = 2008-07-23
draft = false
tags = ["squid", "proxy", "python", "pop3", "imap"]
+++
Mi sono trovato in una situazione piuttosto inusuale: far autenticare a squid degli utenti recuperando le informazioni da un server di posta con un database utenti non consultabile dall'"esterno".
La soluzione è quindi quella di far autenticare gli utenti squid via POP3 e IMAP. Ecco come ho fatto:

Innanzitutto ho preparato degli script in python per tentare l'autenticazione verso il server di posta:

**Versione per POP3**
```python
#!/usr/bin/env python
from poplib import POP3
import sys
# Configurazione: pop server e porta
server = "127.0.0.1"
port = 110
# inizia il ciclo in cui rimanere in ascolto per richieste:
while 1:  
    # legge utente e password dallo standard input
    # forniti come
    # UTENTE PASSWORD\n
    # rimuove \n e splitta lo ' '
    line = sys.stdin.readline()[:-1]
    [user, password] = line.split(' ')
    # crea connessione con il server
    p = POP3(server, port)
    # Cerca di autenticarsi.
    # in caso di autenticazione fallita viene lanciata un'eccezione
    # che deve essere catturata per dire a squid che i dati forniti
    # non sono validi
    try:
        p.user(user)
        p.pass_(password)
    except:
        # autenticazione fallita. butto nello standard error quello che deve venir loggato
        # da squid
        sys.stderr.write("ERR authenticating %s\n" % user)
        # e nello standard output dico a squid di negare l'accesso
        sys.stdout.write("ERR\n")
        # flush dello standard output
        sys.stdout.flush()
        p.quit()
        continue
    # Niente eccezioni => autenticazione corretta
    # Logga l'avvenuta autenticazione (via stderr)
    sys.stderr.write("OK authenticated %s\n" % user)
    # Permette l'accesso
    sys.stdout.write("OK\n")
    sys.stdout.flush()
    p.quit()
```

**Versione per IMAP (similissima a quella per POP3)**
```python
#!/usr/bin/env python
from imaplib import IMAP4
import sys
# Configurazione: imap server e porta
server = "127.0.0.1"
port = 143
# inizia il ciclo in cui rimanere in ascolto per richieste:
while 1:
    # legge utente e password dallo standard input
    # forniti come
    # UTENTE PASSWORD\n
    # rimuove \n e splitta lo ' '
    line = sys.stdin.readline()[:-1]
    [user, password] = line.split(' ')
    # crea connessione con il server
    p = IMAP4(server, port)
    # Cerca di autenticarsi.
    # in caso di autenticazione fallita viene lanciata un'eccezione
    # che deve essere catturata per dire a squid che i dati forniti
    # non sono validi
    try:
        p.login(user, password)
    except:
        # autenticazione fallita. butto nello standard error quello che deve venir loggato
        # da squid
        sys.stderr.write("ERR authenticating %s\n" % user)
        # e nello standard output dico a squid di negare l'accesso
        sys.stdout.write("ERR\n")
        # flush dello standard output
        sys.stdout.flush()
        p.logout()
        continue
    # Niente eccezioni => autenticazione corretta
    # Logga l'avvenuta autenticazione (via stderr)
    sys.stderr.write("OK authenticated %s\n" % user)
    # Permette l'accesso
    sys.stdout.write("OK\n")
    sys.stdout.flush()
    p.logout()
```
(utilizzando altre librerie python non è difficile implementare altri script di autenticazione, ad esempio, basata su un server FTP)

Nel caso la connessione POP3 o IMAP sia da effettuare con SSL, usare la classe POP3_SSL e IMAP4_SSL:
ad esempio, per POP3 SSL, useremo
```python
# ...
from poplib import POP3_SSL
# ...
p = POP3_SSL(server, port)
# ...
```

dopodichè ho inserito nella configurazione di **squid** (nei posti opportuni):
```
auth_param basic program /usr/local/sbin/squid_mailserver_auth.py
auth_param basic realm Proxy Access
acl users proxy_auth REQUIRED
http_access allow users
http_access deny all
```

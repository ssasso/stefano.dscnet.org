+++
title = "Kerberos V su OpenBSD"
date = 2008-07-10
draft = false
tags = ["openbsd", "auth", "autenticazione", "kerberos", "ssh", "bsd"]
+++
Vedremo come configurare un **kerberos V kdc** su **OpenBSD**, come impostare il sistema per autenticarsi sullo stesso e come configurare openssh per accettare login kerberos.

Non tratterò qui nè i principi di funzionamento di kerberos nè la configurazione di un dns autoritativo per un dominio locale,
materiale in rete ce n'è a volontà. Bisogna però sapere che ogni host kerberizzato deve essere registrato nel dns, e deve essere presente un'associazione inversa valida.

Ad esempio, se il nostro host ha ip **192.168.1.1** e si chiama **kdc.gnustile.lan**, dovra esistere un *PTR* a **kdc.gnustile.lan** per **1.1.168.192.in-addr.arpa**.

Ricordiamoci anche che nelle macchine che faranno solo da client non è necessario creare i file di configurazione di kerberos, 
in quanto le informazioni necessarie possono essere ricevute via dns (record SRV appropriati).

ad esempio:
```
$ORIGIN gnustile.lan.
_kerberos            TXT   "GNUSTILE.LAN"
_kerberos._tcp       SRV   10 1 88  kdc.gnustile.lan.
_kerberos._udp       SRV   10 1 88  kdc.gnustile.lan.
_kpasswd._udp        SRV   10 1 464 kdc.gnustile.lan.
_kerberos-adm._tcp   SRV   10 1 749 kdc.gnustile.lan.
```
Detto questo, passiamo alla pratica.

**OpenBSD** include **Heimdal kerberos V**. Vediamo come renderlo operativo:
per prima cosa dobbiamo editare il file di configurazione, */etc/kerberosV/krb5.conf*
(troviamo un esempio del file in */etc/kerberosV/krb5.conf.sample*)

il contenuto dovrà essere qualcosa simile al seguente:
```
[libdefaults]
        # Set the realm of this host here
        default_realm = GNUSTILE.LAN
        # Maximum allowed time difference between KDC and this host
        clockskew = 300
        # Uncomment this if you run NAT on the client side of kauth.
        # This may be considered a security issue though.
        # no-addresses = yes
[realms]
        GNUSTILE.LAN = {
                # Specify KDC here
                kdc = kdc.gnustile.lan
                # Administration server, used for creating users etc.
                admin_server = kdc.gnustile.lan
        }
# This sections describes how to figure out a realm given a DNS name
[domain_realm]
        .gnustile.lan = GNUSTILE.LAN
[kadmin]
        # This is the trickiest part of a Kerberos installation. See the
        # heimdal infopage for more information about encryption types.
        # For a k5 only realm, this will be fine
        default_keys = v5
[logging]
        # The KDC logs by default, but it's nice to have a kadmind log as well.
        kadmind = FILE:/var/heimdal/kadmind.log
```
passiamo ora alla creazione del database:

creiamo la cartella in cui risiederà
```bash
mkdir /var/heimdal
cd /var/heimdal
```
e creiamo la master-key:
```bash
kstash
```
passiamo quindi alla creazione vera e propria:

entriamo nella console di amministrazione con:
```bash
kadmin -l
```
e poi
```
kadmin> init GNUSTILE.LAN
    Realm max ticket life [unlimited]:
    Realm max renewable ticket life [unlimited]:
```
aggiungiamo quindi il nostro primo utente
```
kadmin> add utente1
    Max ticket life [unlimited]:
    Max renewable life [unlimited]:
    Attributes []:
    Password: (inseriamo la password)
    Verifying password - Password: (confermiamola)
```
usciamo quindi dalla console di amministrazione:
```
kadmin> exit
```
facciamo partire il servizio **kdc** con:
```bash
/usr/libexec/kdc &
```
e proviamo a recuperare un ticker per l'utente appena creato:
```bash
kinit utente1
klist
```
Dovremmo ottenere un output del tipo:
```
Credentials cache: /tmp/krb5cc_0
        Principal: utente1@GNUSTILE.LAN
  Issued           Expires          Principal
Jun 9 07:25:55  Jun 9 17:25:55  krbtgt/GNUSTILE.LAN@GNUSTILE.LAN
```

Possiamo far partire al boot il KDC modificando la riga:
```
krb5_master_kdc=NO
```
in:
```
krb5_master_kdc=YES
```
nel file */etc/rc.conf*.

Entriamo di nuovo nella console kadmin e creiamo ora la chiave per il nostro host:
```bash
kadmin -l
```
```
kadmin> add --random-key host/kdc.gnustile.lan
    Max ticket life [unlimited]:
    Max renewable life [unlimited]:
    Attributes []:
```
e la estraiamo nel keytab. (*/etc/kerberosV/krb5.keytab*)
```
kadmin> ext host/kdc.gnustile.lan
```
procediamo allo stesso modo per tutte le macchine kerberizzate della nostra rete:
```
kadmin> add --random-key host/server1.gnustile.lan
```
e estraiamo in un keytab "esterno", che poi porteremo in maniera sicura sulle macchine e rinomineremo in */etc/kerberosV/krb5.keytab*.
```
kadmin> ext --keytab=/root/keytab.server1 host/server1.gnustile.lan
```

Se vogliamo consentire l'amministrazione remota dobbiamo configurare e far partire il demone **kadmind**, (con la configurazione precedente in *rc.conf* parte automaticamente)
```
/usr/libexec/kadmind &
```

dobbiamo poi definire che utenti, e con che privilegi, potranno accedere al database kerberos che risiede su **kdc.gnustile.lan**

editiamo quindi il file */var/heimdal/kadmind.acl*:
```
stefano/admin@GNUSTILE.LAN    all
adminmenu/admin@GNUSTILE.LAN  change-password
```
avviamo anche il demone per il cambio password da remoto (partirà comunque automaticamente al boot)
```bash
/usr/libexec/kpasswdd &
```

Settiamo ora una politica per la complessità delle password:
ri-editiamo */etc/kerberosV/krb5.conf* e aggiungiamo:
```
[password_quality]
        policies = minimum-length character-class
        min_length = 8
        min_classes = 3
```
in questo modo le password dovranno essere lunghe almeno 8 caratteri, e dovranno contenere almeno 3 classi di caratteri (le classi sono: lettere minuscole, lettere maiuscole, numeri, simboli).

Vediamo ora come creare una classe di utenti per il login di sistema con kerberos:
editiamo */etc/login.conf* e aggiungiamo:
```
kuser:\
      :path=/usr/bin /bin /usr/sbin /sbin /usr/X11R6/bin /usr/local/bin:\
      :umask=022:\
      :datasize-max=512M:\
      :datasize-cur=512M:\
      :maxproc-max=128:\
      :maxproc-cur=64:\
      :openfiles-cur=128:\
      :stacksize-cur=5M:\
      :auth=krb5:
```
poi modifichiamo */etc/adduser.conf* aggiungendo all'array *login_classes* anche *kuser*.

Creiamo ora il nostro utente, con il comando `adduser`:
```
Reading /etc/shells
Check /etc/master.passwd
Check /etc/group
Ok, let's go.
Don't worry about mistakes. There will be a chance later to correct any input.
Enter username []: utente1
Enter full name []: Utente kerberizzato 1
Enter shell csh ksh nologin sh [ksh]:
Uid [1003]:
Login group utente1 [utente1]:
Login group is ``utente1''. Invite utente1 into other groups: guest no
[no]:
Login class authpf daemon default kuser staff [default]: kuser
Enter password []: (non insieriamo niente qui, la password è già memorizzata nel database kerberos)
Set the password so that user cannot logon? (y/n) [n]: y
Name:        utente1
Password:    ****
Fullname:    Utente kerberizzato 1
Uid:         1003
Gid:         1003 (utente1)
Groups:      utente1
Login Class: kuser
HOME:        /home/utente1
Shell:       /bin/ksh
OK? (y/n) [y]: y
Added user ``utente1''
```

Proviamo ora a fare login come **utente1**, con la password precedentemente inserita nel database kerberos;
una volta fatto login verifichiamo di avere il ticket con il comando `klist`:
```
Credentials cache: FILE:/tmp/krb5cc_xByrs21856
        Principal: utente1@GNUSTILE.LAN
  Issued           Expires          Principal
Jul  9 15:50:38  Jul 10 01:50:38  krbtgt/GNUSTILE.LAN@GNUSTILE.LAN
```

configuriamo ora ssh per consentire login kerberizzati:
modifichiamo i seguenti parametri in */etc/ssh/sshd_config*:
```
PubkeyAuthentication no
ChallengeResponseAuthentication yes
KerberosAuthentication yes
KerberosOrLocalPasswd yes
KerberosTicketCleanup yes
GSSAPIAuthentication yes
```
e questi in */etc/ssh/ssh_config*:
```
Host *
  ForwardAgent no
  ForwardX11 yes
  RSAAuthentication yes
  PasswordAuthentication yes
  GSSAPIAuthentication yes
```
Molto bene, ora dovrebbe funzionare tutto (dopo aver riavviato **sshd**) :)

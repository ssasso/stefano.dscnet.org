+++
title = "Apache 2 e mod_rewrite come load balancer http"
date = 2009-07-31
draft = false
tags = ["linux", "apache", "cluster", "http", "load balancer", "mod_rewrite", "proxy"]
+++

Ipotizziamo di voler bilanciare un'applicazione web su due backend, ma di non voler utilizzare uno storage condiviso.

Ipotizziamo anche che l'applicazione necessiti di accesso a disco solo per salvare le informazioni di sessione, mentre il database a cui accede sia su una macchina separata.

Ogni singolo utente dovrebbe quindi accedere solo ad uno dei server di backend (e sempre a quello), in modo da trovare intatte le sue informazioni di sessione.
(Questa soluzione è solo per bilanciamento, non per alta disponibilità!)

Vediamo come è possibile realizzare il bilanciatore con *apache*, *mod_proxy* e qualche regola di *rewrite*.

```
<VirtualHost *:80>
ServerName lb.gnustile.lan
ServerAdmin sysadm@gnustile.lan

ErrorLog /var/log/apache2/lb_error.log
LogLevel warn

proxyPreserveHost On

RewriteEngine On

RewriteMap SERVERS rnd:/etc/apache2/dat/lb_servers.conf
RewriteMap RNC rnd:/etc/apache2/dat/random_numbers.conf

# Controlla l'esistenza del cookie "_bes", che indica che
# una sessione di bilanciamento è già attiva.
# Redirige quindi al backend indicato nel cookie
# (per mascherare le informazioni il cookie è nella forma
# <stringa_random>-<nome_backend>-<numero_random>
# )
RewriteCond %{HTTP_COOKIE} "_bes=(.+)-(.+)-(.+)"
# recupera ora, a partire dal nome del backend, il nome e il server
# il primo elemento è il nome del BE, il secondo il BE
RewriteCond ${SERVERS:%2} (.+)::(.+)
# redirige via mod_proxy e imposta 2 variabili d'ambiente (per facilitare il logging)
RewriteRule /(.*) http://%2/$1 [P,L,E=BE:%1,E=BES:%2]

# Se non è presente il cookie di "sessione" (o se non è valido)
# usa un backend random e crea il cookie.

# determina l'host, in modo da renderlo unico e disponibile in %1 e %2
RewriteCond ${SERVERS:ALL} (.+)::(.+)
# il primo elemento è il nome del BE, il secondo il BE
# setta inoltre il cookie _bes per HTTP_HOST
RewriteRule /(.*) http://%2/$1 [P,L,E=BE:%1,E=BES:%2,CO=_bes:${RNC:C}-%1-${RNC:N}:%{HTTP_HOST}]

proxyPassReverse / http://app1.gnustile.lan/
proxyPassReverse / http://app2.gnustile.lan/
proxyPassReverse / http://app3.gnustile.lan/

CustomLog /var/log/apache2/lb_access.log "[BE::%{BE}e::%{BES}e::C::%{_bes}C] %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"

</VirtualHost>
```

Il file */etc/apache2/dat/lb_servers.conf* contiene

```
BE1  BE1::app1.gnustile.lan
BE2  BE2::app2.gnustile.lan
BE3  BE3::app3.gnustile.lan
ALL  BE1::app1.gnustile.lan|BE2::app2.gnustile.lan|BE3::app3.gnustile.lan
```

Il file è così strutturato per recuperare, oltre al server di backend, anche il nome dello stesso.

Il file */etc/apache2/dat/random_numbers.conf* è stato generato con uno script e contiene qualcosa del tipo

```
N  1122|1144|...altri numeri random...
C  z43rewrjcqw|irje8wr34|...altre stringhe random...
```

Se proprio vi interessa ecco lo script generatore:
(ovviamente l'output andrà rediretto al file usato da mod_rewrite)

```perl
#!/usr/bin/perl

sub generate_random_string
{
  my $length_of_randomstring=shift;
  my @chars=('a'..'z','A'..'Z','0'..'9','.','_');
  my $random_string;
  foreach (1..$length_of_randomstring) 
  {
    $random_string.=$chars[rand @chars];
  }
  return $random_string;
}

my $seq = 10000;
my $strlen = 25;
my $range = 99999999;

@els = ();

for ($i = 0; $i < $seq; $i++) {
  my $rn = &generate_random_string($strlen);
  push(@els, $rn);
}

$res = join('|', @els);

print "C\t" . $res . "\n";

@els = ();

for ($i = 0; $i < $seq; $i++) {
  my $rn = int(rand($range));
  push(@els, $rn);
}

$res = join('|', @els);

print "N\t" . $res . "\n";
```
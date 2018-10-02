+++
title = "Apache: definire macro con mod_macro"
date = 2007-12-10
draft = false
tags = ["apache", "mod_macro"]
+++
**mod_macro** rende il lavoro di amministrazione di apache più semplice e veloce.

per prima cosa dobbiamo installare ed attivare il modulo
```bash
apt-get install libapache2-mod-macro
a2enmod macro
/etc/init.d/apache2 restart
```
vediamo subito un esempio che ci aiuterà a capire il comportamento
```
<Macro Logfile>
	CustomLog /var/log/apache2/access.log combined
	ErrorLog /var/log/apache2/error.log
	LogLevel warn
</Macro>
```
per usare la macro basterà inserire
```
Use Logfile
```
è possibile passare alla macro anche delle variabili:
```
<Macro Logfiles $sitename>
	CustomLog /var/log/apache2/$sitename-access.log combined
	ErrorLog /var/log/apache2/$sitename-error.log
	LogLevel warn
</Macro>
```
e per usare la macro
```
Use Logfiles dominio1.com
```
In generale la sintassi di `Use` è
```
Use <Nome_macro> [Variabile 1] [Variabile 2] ... [Variabile x]
```
l'ideale sarebbe scrivere tutte le macro nel file */etc/apache2/conf.d/macros.conf*, in modo che venga automaticamente incluso da apache.

Vediamo qualche configurazione più avanzata:

è anche possibile annidare macro:
```
<Macro VHost $tipo $hostname>
<VirtualHost *>
	ServerName $hostname
	ServerAlias www.$hostname
	ServerAdmin webmaster@$hostname
	DocumentRoot /srv/www/$hostname
	Use VHTipo_$tipo $hostname
	CustomLog /var/log/apache2/$hostname-access.log combined
	ErrorLog /var/log/apache2/$hostname-error.log
	LogLevel warn
	ServerSignature Off
</VirtualHost>
</Macro>
<Macro VHTipo_static_pages_with_cgi $hostname>
	ScriptAlias /cgi-bin/ /srv/www/$hostname/cgi-bin/
</Macro>
```
L'uso sarà
```
Use VHost only_static_pages dominio1.com
Use VHost static_pages_with_cgi dominio2.com
Use VHost with_php dominio3.com
```
+++
title = "Apache 2 mass virtual hosting con mod_rewrite"
date = 2007-12-10
draft = false
tags = ["apache", "mod_rewrite"]
+++
Come avere dei virtual host configurati automaticamente senza dover riavviare apache ogni volta:
```
<VirtualHost 192.168.17.123>
  DocumentRoot /srv/web
  <DirectoryMatch "^/srv/web/(.+)/cgi-bin>
    Options None
    Options +ExecCGI
  </DirectoryMatch>    
  RewriteEngine on
  RewriteMap lowercase int:tolower
    
  RewriteMap vhost txt:/etc/apache2/vhost.map
    
  RewriteCond %{REQUEST_URI} !^/icons/
  RewriteCond %{REQUEST_URI} !^/cgi-bin/
  RewriteCond ${lowercase:%{SERVER_NAME}} ^(www\.)?(.+)$
  RewriteCond ${vhost:%2} ^(/.*)$
  RewriteRule ^/(.*)$ %1/htdocs/$1
  RewriteCond %{REQUEST_URI} ^/cgi-bin/
  RewriteCond ${lowercase:%{SERVER_NAME}} ^(www\.)?(.+)$
  RewriteCond ${vhost:%2} ^(/.*)$
  RewriteRule ^/cgi-bin/(.*)$ %1/cgi-bin/$1 [T=application/x-httpd-cgi]
# ...
</VirtualHost>
```
il file *vhost.map* conterrà qualcosa di simile a
```
customer-1.com /srv/web/customer-1/www
customer-2.com /srv/web/customer-2/www
customer-n.com /srv/web/customer-1/www
```
in alternativa, invece di un file di testo, è possibile fare interrogazioni ad un database usando un piccolo programmino esterno, come questo esempio in php:

al posto di
```
RewriteMap vhost txt:/etc/apache2/vhost.map
```
inserire
```
RewriteMap vhost prg:/etc/apache2/scripts/vhostmap.php
```
il file *vhostmap.php* deve essere simile a
```php
#!/usr/bin/php -q
<?php
@mysql_connect("127.0.0.1", "web", "web") || ($err = 1);
$fdin = fopen("php://stdin", "r");
$fdout = fopen("php://stdout", "w");
set_file_buffer($fdout, 0);
while( $l = fgets($fdin, 256))
{
    if ($err)
        fputs($fdout, "NULL\n");
    else
        fputs($fdout, vhostLookup($l) . "\n");
}
function vhostLookup($host)
{
    $res = mysql_query("SELECT dir FROM web.vhosts WHERE host = \"".$host."\";");
    if (@mysql_num_rows($res))
    {
        $r = @mysql_fetch_row();
        return $r['dir'];
    }
    else
        return $host;
}
?>
```

### ...il problema dei log...

Con questa configurazione apache traccia tutte le attività in un unico file, rendendo praticamente impossibile l'identificazione di quelli di un sito in particolare.
Il metodo più semplice è quello di definire un paio di variabili come parte integrante di Rewrite, per poi includerle nei log.
L'ultimo passo consiste nello scrivere uno script per cercare tra i vari log quelli di un utente.

La configurazione di apache deve risultare quindi
```
...
RewriteRule ^/(.*)$ %1/htdocs/$1 [E=VHOST:%{SERVER_NAME}]
...
RewriteRule ^/cgi-bin/(.*)$ %1/cgi-bin/$1 [T=application/x-httpd-cgi,E=VHOST:%{SERVER_NAME}]
...
CustomLog "/var/log/apache2/v_access_log" "%{VHOST}e %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"
...
```
in alternativa, al posto di */var/log/apache2/v_access_log*, possiamo utilizzare lo script *cronolog*
```
CustomLog "|/usr/sbin/cronolog /var/log/apache2/vhost/%Y/%m/%d/access_log" "%{VHOST}e %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"
```
+++
title = "WebDAV root directory basata su utente"
date = 2007-12-10
draft = false
tags = ["apache", "webdav", "dav", "mod_rewrite"]
+++
Questo ci permette di avere delle root directory DAV diverse a seconda dell'utente che ha fatto il login.

Le parti fondamentali della configurazione di **apache 2** sono:
```
<VirtualHost 192.168.17.124>
  ServerName dav.gnustile.lan
  ServerAlias dav.*
  DocumentRoot /srv/web
    
  <Directory /srv/web>
    DAV On
    Options Indexes
    Options +FollowSymLinks
    AllowOverride None
    DirectoryIndex .NonExistentFile1234567890
    AuthType Basic
    AuthName "WebDAV"
    AuthUserFile /etc/apache2/vhost.dav
    require valid-user
  </Directory>
  RewriteEngine On
  RewriteCond %{REQUEST_URI} !^/icons/
  RewriteRule ^/(.*) /srv/web/%{LA-U:REMOTE_USER}/$1
  <Location /icons>
    <LimitExcept GET>
      deny from all
    </LimitExcept>
  </Location>
# ...
</VirtualHost>
```
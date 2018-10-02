+++
title = "Apache in manutenzione"
date = 2007-12-08
draft = false
tags = ["apache", "mod_rewrite"]
+++
Ecco un modo user-friendly per fare si che il server non sia accessibile se ci stiamo lavorando:
```
RewriteEngine On
RewriteCond %{DOCUMENT_ROOT}/maintenance.html -f
RewriteCond %{SCRIPT_FILENAME} !maintenance.html
RewriteRule ^.*$ /maintenance.html [R,L]
```
se esiste il file *maintenance.html* nella document root, allora tutte le richieste verranno indirizzate li.
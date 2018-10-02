+++
title = "URL rewriting verso https"
date = 2007-12-08
draft = false
tags = ["apache", "mod_rewrite"]
+++
```
RewriteEngine On
RewriteCond %{SERVER_PORT} !443
RewriteRule ^/(.*)$ https://domain.com/$1 [R=301,L]
```
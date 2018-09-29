+++
title = "Il mio fooldns personale"
date = 2008-09-14
draft = false
tags = ["bind", "dns"]
+++
Niente di male contro i creatori di fooldns, hanno avuto un'idea carina per bloccare i troppi adv in maniera quasi trasperente, solo che preferisco tenere personalmente sotto controllo cosa viene bloccato.
Per questo ho pensato di realizzarmi in casa, per la mia rete, una soluzione simile.

Questo sistema usa **bind9** come server DNS. Non escludo la possibilità di portarlo su **djbdns**.

L'ho chiamato il **folletto blocca-banner**, perchè folletto è la prima parola che mi è venuta in mente partendo da "fool" :)

Ecco la realizzazione:

in *named.conf* inserire:
```
include "/etc/bind/zones.folletto";
```
e *zones.folletto* verrà popolato in automatico con, ad esempio (prendendo spunto da un template)
```
zone "ads.dominio.it" {
  type master;
  file "/etc/bind/folletto.db";
};
```
mentre *folletto.db* conterrà:
```
$TTL    604800
@       IN      SOA     localhost. root.gnustile.lan. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      localhost.
@       IN      A       127.127.127.127
```
(sostituire 127.127.127.127 con l'indirizzo IP della vostra macchina che farà da server DNS, e con apache installato)

Lo script di gestione quindi:

* parsa l'elenco degli host da bannare,
* genera nuovo ogni volta zones.folletto a partire dal template

file contentente gli host da bannare: (esempio)
```
ads.dominio.it
ads.dominio.com
ads.dominio.net
```

scriptino per generare *zones.folletto*:
```ruby
#!/usr/bin/ruby
template=File.read('zones.folletto.tpl')
out_file=""
File.read('da_bannare.txt').each_line do |host|
  host.chomp!
  if host!=""
    current_template=template.gsub('{HOST}', host)
    out_file=out_file+"\n"+current_template+"\n"
  end
end

File.open('zones.folletto', 'w') do |f|
  f.write out_file
end
```

e *zones.folletto.tpl*:
```
zone "{HOST}" {
  type master;
  file "/etc/bind/folletto.db";
};
```

Mentre, per quanto riguarda il virtualhost apache, è stata inserita la seguente regola di rewrite:
```
RewriteRule   ^(.*)\.(js)$  catcher.php?q=$1.js [L,QSA]
```
che manda tutti i js, dei siti di ad, a *catcher.php*, il cui codice è:
```php
<?
Header("content-type: application/x-javascript");

$url=$_SERVER['HTTP_HOST']."/".$_GET['q'];
?>

messaggio="Il folletto blocca-banner ha bloccato la pubblicita` che doveva essere presente qui.\n"
messaggio=messaggio+"Il folletto blocca-banner di questa rete e` stato interamente creato da stefano :)"

if (!xFollettoOk){
  document.write("<iframe style='width: 130px; height: 80px;' valign=center allowtransparency='true'");
  document.write(" src='http://127.127.127.127/iframe.php?url=<?=$url?>' ");
  document.write("scrolling='no' frameborder='no' style='border-width:0'></iframe>");
}
else
{
  document.write("<img src=\"http://127.127.127.127/adblock.png\" onclick=\"alert(messaggio)\"/>");
}
var xFollettoOk = true;
```

ovvero, mostra un iframe per il primo banner, e un'immagine per tutti gli altri.

*iframe.php* è:
```html
<div style="text-align: center; padding: 2px 2px 2px 2px; border: 1px solid Black;">
<font color="red" size="1">
<i>il folletto sta proteggendo questa pagina dalla pubblicità</i>
</font>
</div>
```

... e tutto mi risulta funzionare :)

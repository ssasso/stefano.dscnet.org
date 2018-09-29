+++
title = "Monitoraggio di exim con snmp e mrtg"
date = 2008-12-19
draft = false
tags = ["exim", "exim4", "mrtg", "snmp"]
+++
Per prima cosa ho installato snmpd:
```bash
apt-get install snmp snmpd
```
poi ho configurato le cose di base, ovvero l'uso della community public e le informazioni del sistema:
```
com2sec readonly  default         public

syslocation MI
sysname xyzrelay.cust.gnustile.net
syscontact S.Sasso <root@xyzrelay.cust.gnustile.net>
```
ho quindi creato uno script per raccogliere le statistiche e inserirle in un file di log, che poi verrà recuperato da snmpd (grazie ad un'altro script).

*/usr/local/sbin/scan_exim_log.pl*
```perl
#!/usr/bin/perl

use POSIX qw(strftime);

$TOTAL = "/var/log/scan_exim_log.total";
$EXIM = "/usr/sbin/exim";

$number_in = $number_out = $cancelled = $rejected = 0;
$frozen = $queued = $to_deliver = $qkb = $largest = 0;

open(LOG,"</var/log/exim4/mainlog")
  || die "$0: couldn't open mainlog: $!";
while(<LOG>) {
  if (/<=/) {
    $number_in++;
  } elsif (/[-=]>/) {
    $number_out++;
  } elsif (/cancelled by system filter:/) {
    $cancelled++;
  }
}
close(LOG);

$now = strftime("%Y-%m-%d %H:%M", gmtime(time - 300));

open(LOG,"</var/log/exim4/rejectlog")
  || die "$0: couldn't open rejectlog: $!";
while(<LOG>) {
  if (/rejected/) {
    $rejected++;
  }
}
close(LOG);

open(MAILQ, "$EXIM -bp|")
  || die "$0: couldn't open pipe from Exim ($EXIM): $!";
while(<MAILQ>) {
  chop;
  if (/[<>]/) {
    $frozen++ if /frozen/;
    $queued++;

    s/\s+/ /g;
    my ($time, $size, $msgid, $sender) = split;

    if ($size =~ /K$/) {
      $size =~ s/K$//;
      $size *= 1024;         # multiply by 1024 to go from KB -> bytes
      $qkb += int($size);
    } elsif ($size =~ /M/) {
      $size =~ s/M$//;
      $size *= 1024;         # multiply by 1024 to go from MB -> KB
      $size *= 1024;         # multiply by 1024 to go from KB -> bytes
      $qkb += int($size);
    } else {
      $qkb += int($size);
    }

    if ($size > $largest) {
      $largest = int($size);
    }
  } else {
    next if /D /;
    $to_deliver++;
  }
}
close(MAILQ);

open(TOTAL,">$TOTAL.$$")
  || die "Can't write the file 'scan_exim_log.total.$$'\n";
print TOTAL <<EOF;
$frozen
$queued
$to_deliver
$qkb
$largest
$number_in
$number_out
$rejected
EOF
close(TOTAL);

rename("/var/log/scan_exim_log.total.$$", "/var/log/scan_exim_log.total");
```

*/usr/local/sbin/qpeek.pl*
```perl
#!/usr/bin/perl

$TOT = "/var/log/scan_exim_log.total";

open(EXIM_TOTALS, "$TOT")
  || die "$0: couldn't open Exim totals $TOT: $!";
while() {
  chop;
  print "$_\n";
}
close(EXIM_TOTALS);
```

inserisco quindi in *snmpd.conf*
```
exec .1.3.6.1.4.1.3032.64 qpeek.pl /usr/local/sbin/qpeek.pl
```
e riavvio snmpd:
```bash
/etc/init.d/snmpd restart
```
Inserisco ora una entry nel crontab per recuperare le statistiche ogni 5 minuti:

*/etc/cron.d/scan_exim_logs*
```
*/5 *   * * *   root    /usr/local/sbin/scan_exim_log.pl >/dev/null 2>&1
```

Si presuppone poi che mrtg sia già stato configurato per monitorare rete, memoria, cpu, etc...; vedremo solo come configurarlo per graficare le statistiche di exim;

aggiungiamo quindi alla configurazione di mrtg (*/etc/mrtg.cfg*):
```
# queued messages to deliver
Target[queued]: 1.3.6.1.4.1.3032.64.101.3&1.3.6.1.4.1.3032.64.101.3:public@localhost
Title[queued]: Messages to deliver (full queue)
MaxBytes[queued]: 10000
PageTop[queued]: <H1>Messages to deliver (full queue)</H1>
YLegend[queued]: Messages
ShortLegend[queued]: msgs
LegendI[queued]: Messages to deliver
LegendO[queued]:
Legend1[queued]: Messages to deliver
Legend2[queued]:
Options[queued]: growright,nopercent,gauge

# queued vs frozen
Target[queuedfrozen]: 1.3.6.1.4.1.3032.64.101.2&1.3.6.1.4.1.3032.64.101.1:public@localhost
Title[queuedfrozen]: Queued vs. frozen messages
MaxBytes[queuedfrozen]: 15000
PageTop[queuedfrozen]: <H1>Queued vs. frozen messages</H1>
YLegend[queuedfrozen]: Messages
LegendI[queuedfrozen]: Queued
LegendO[queuedfrozen]: Frozen
Legend1[queuedfrozen]: Queued
Legend2[queuedfrozen]: Frozen
ShortLegend[queuedfrozen]: msgs
Options[queuedfrozen]: growright,nopercent,gauge

# queue size
Target[qkblargest]: 1.3.6.1.4.1.3032.64.101.4&1.3.6.1.4.1.3032.64.101.5:public@localhost
Title[qkblargest]: Queue size vs largest msg.
MaxBytes[qkblargest]: 100000000000
PageTop[qkblargest]: <H1>Queue size vs largest msg.</H1>
YLegend[qkblargest]: Size
LegendI[qkblargest]: Queue size
LegendO[qkblargest]: Largest size
Legend1[qkblargest]: Queue size
Legend2[qkblargest]: Largest size
Options[qkblargest]: growright,nopercent,gauge
ShortLegend[qkblargest]: b

# In/Out
Target[msginout]: 1.3.6.1.4.1.3032.64.101.6&1.3.6.1.4.1.3032.64.101.7:public@localhost
Title[msginout]: In vs Out (msg)
MaxBytes[msginout]: 100000000000
PageTop[msginout]: <H1>In vs Out (msg)</H1>
YLegend[msginout]: Messages
LegendI[msginout]: In
LegendO[msginout]: Out
Legend1[msginout]: In Messages
Legend2[msginout]: Out Messages
Options[msginout]: growright,nopercent,gauge
ShortLegend[msginout]: msgs

# rejected
Target[rejected]: 1.3.6.1.4.1.3032.64.101.8&1.3.6.1.4.1.3032.64.101.8:public@localhost
Title[rejected]: Rejected at SMTP time
MaxBytes[rejected]: 10000
PageTop[rejected]: <H1>Rejected at SMTP time</H1>
YLegend[rejected]: Messages
ShortLegend[rejected]: msgs
LegendI[rejected]: Rejected
LegendO[rejected]:
Legend1[rejected]: Rejected
Legend2[rejected]:
Options[rejected]: growright,nopercent,gauge
```

rigeneriamo poi l'indice di mrtg
```bash
indexmaker /etc/mrtg.cfg --columns=2 --output /var/www/mrtg/index.html
```
e lanciamo un paio (o più :) ) di volte mrtg stesso, per generare i primi dati
```bash
mrtg ; mrtg ; mrtg
```
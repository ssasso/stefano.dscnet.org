+++
title = "Configurazione base exiscan-acl"
date = 2007-12-10
draft = false
tags = ["exim", "exim4", "antispam", "antivirus"]
+++
**exiscan-acl** sono una serie di estensioni di exim che consentono la scansione antispam/antivirus direttamente nelle direttive acl di helo.
```
av_scanner = clamd:192.168.177.44 3310
spamd_address = 192.168.177.45 783
begin acl
 acl_check_data:
  # antivirus
  deny message   = This message contains malware ($malware_name)
       demime    =*
       malware   =*
  deny message   = Message scored $spam_score spam points.
       condition = ${if <{$message_size}{150k}{1}{0}}
       spam      = nobody:true
       condition = ${if >{$spam_score_int}{150}{1}{0}}
```
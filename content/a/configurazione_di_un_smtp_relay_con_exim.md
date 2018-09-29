+++
title = "Configurazione di un smtp relay con exim"
date = 2008-12-19
draft = false
tags = ["linux", "exim", "exim4", "perl", "relay", "smtp"]
+++
Ho dovuto installare un relay smtp, e ho deciso di usare exim 4... ecco come ho fatto:

*/etc/exim4/exim4.conf*
```
# carica la funzione perl per la verifica dell'autenticazione smtp
perl_startup = do '/etc/exim4/smtpd_passwd_check.pl'
perl_at_start

# imposta info. di base
primary_hostname = xyzrelay.cust.gnustile.net
qualify_domain = xyzrelay.cust.gnustile.net
smtp_banner = $smtp_active_hostname ESMTP\n$tod_full\nspammers, stop waste your time!\n*** NO SPAM ALLOWED HERE ***
never_users = root
hostlist   relay_from_hosts = 127.0.0.1 : aa.bb.cc.de : aa.bb.cc.df
domainlist local_domains = @ : localhost : xyzrelay.cust.gnustile.net
domainlist relay_to_domains =
host_lookup = *
rfc1413_hosts = *
rfc1413_query_timeout = 0s
smtp_accept_reserve = 100
smtp_reserve_hosts = 127.0.0.1 : ::::1 : aa.bb.cc.de : aa.bb.cc.df
ignore_bounce_errors_after = 3d
timeout_frozen_after = 3d

# custom queue/delivery options
message_size_limit = 50M
return_size_limit = 100K
remote_max_parallel = 8
smtp_accept_queue = 1500
smtp_accept_max = 1500
smtp_accept_max_per_host = 1500
smtp_accept_queue_per_connection = 1500
queue_run_max = 32

# TLS/SSL
tls_advertise_hosts = *
tls_certificate = /etc/exim4/exim4.pem
tls_privatekey = /etc/exim4/exim4.pem
daemon_smtp_ports = 25 : 465 : 587
tls_on_connect_ports = 465

# definisce le acl da usare nelle varie situazioni
acl_smtp_helo = acl_check_helo
acl_smtp_rcpt = acl_check_rcpt
acl_smtp_data = acl_check_content

begin acl

acl_check_helo:
  # accetta se arriva da pipe locale (no tcp/ip)
  accept hosts     =:

  # accetta se arriva da un host da cui e` permesso il relay
  accept hosts     = +relay_from_hosts

  # rate limit, al massimo 1500 email per ora da un host
  defer message    = Sender rate exceeds $sender_rate_limit messages \
                     per $sender_rate_period
        ratelimit  = 1500 / 1h / per_conn / leaky / $sender_host_address

  accept

acl_check_rcpt:
  # accetta se arriva da pipe locale (no tcp/ip)
  accept hosts          =:

  # nega il relay se l'indirizzo comincia con un .
  deny    local_parts   = ^.*[@%!/|] : ^\\.

  # accetta da sorgente autenticata
  accept authenticated = *
         control       = submission

  # DEVE FARE ORA UNA SERIE DI CONTROLLI SULLA VALIDITÀ DELL'HELO/EHLO
  # IN QUANTO SE FATTI PRIMA DELLA VERIFICA AUTENTICAZIONE SI RISCHIAVA
  # DI FARE REJECT DI QUALCHE MUA BACATO...
  
  # droppa se ricevo un ip come HELO
  drop   condition = ${if match{$sender_helo_name}{^[0-9]\.[0-9]\.[0-9]\.[0-9]}{yes}{no}}
         message   = "Dropped IP-only or IP-starting helo"

  # helo non valido (RFC2821 4.1.3)
  drop   condition = ${if isip{$sender_helo_name}}
         message   = Access denied - Invalid HELO name (See RFC2821 4.1.3)
  
  # helo non fqdn
  drop   condition = ${if match{$sender_helo_name}{\N^\[\N}{no}{yes}}
         condition = ${if match{$sender_helo_name}{\N\.\N}{no}{yes}}
         message   = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)
  drop   condition = ${if match{$sender_helo_name}{\N\.$\N}}
         message   = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)
  drop   condition = ${if match{$sender_helo_name}{\N\.\.\N}}
         message   = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)

  # helo e' il mio hostname
  drop   message   = "REJECTED - Bad HELO - Host impersonating [$sender_helo_name]"
         condition = ${if match{$sender_helo_name}{$primary_hostname}{yes}{no}}
  
  # helo e' uno dei domini gestiti da me
  drop   message   = "REJECTED - Bad HELO - Host impersonating [$sender_helo_name]"
         condition = ${if match_domain{$sender_helo_name}{+local_domains}{true}{false}}

  # DNS-BL
  drop message  = REJECTED - ${sender_host_address} is blacklisted at \
                   $dnslist_domain ($dnslist_value); ${dnslist_text}
       dnslists = sbl-xbl.spamhaus.org/<;$sender_host_address;$sender_address_domain
  drop message  = REJECTED - ${sender_address_domain} is blacklisted at \
                   ${dnslist_domain}; ${dnslist_text}
       dnslists = nomail.rhsbl.sorbs.net/$sender_address_domain
  drop message  = REJECTED - ${sender_host_address} is blacklisted at \
                    ${dnslist_domain}; ${dnslist_text}
       dnslists = zen.spamhaus.org : cbl.abuseat.org

  # i messaggi bounce da postmaster@ sono inviate solo ad un indirizzo
  drop    message       = Legitimate bounces are never sent to more than one recipient.
          senders       = : postmaster@*
          condition     = ${if >{$recipients_count}{1}{true}{false}}
  
  # cancella se ci sono più di 5 destinazioni fallite
  drop    message       = REJECTED - Too many failed recipients - count = $rcpt_fail_count
          log_message   = REJECTED - Too many failed recipients - count = $rcpt_fail_count
          condition     = ${if > {${eval:$rcpt_fail_count}}{5}{yes}{no}}
          !verify       = recipient/callout=2m,defer_ok,use_sender

  # accetta tutte le mail per postmaster locali
  accept local_parts    = postmaster
         domains        = +local_domains
  
  # accetta le mail per i domini locali, dopo aver verificato il recipient
  accept domains        = +local_domains
         endpass
         verify         = recipient

  # accetta se il relay è consentito
  accept hosts          = +relay_from_hosts

  # non consente il resto
  deny    message       = relay not permitted

acl_check_content:

  # blocca se sia il soggetto che il testo sono vuoti
  deny    message       = REJECTED - No Subject nor body
          !condition    = ${if def:h_Subject:}
          condition     = ${if <{$body_linecount}{1}{true}{false}}

  accept

begin routers

external_gw:
  driver = dnslookup
  transport = remote_smtp
  domains = ! +local_domains
  no_more

system_aliases:
  driver = redirect
  allow_fail
  allow_defer
  data = ${lookup{$local_part}lsearch{/etc/aliases}}
  user = mail
  group = mail
  local_part_suffix = +*
  local_part_suffix_optional
  headers_remove = Delivered-To
  headers_add = Delivered-To: $local_part$local_part_suffix@$domain
  file_transport = address_file
  pipe_transport = address_pipe

localuser:
  driver = accept
  check_local_user
  transport = local_delivery
  cannot_route_message = Unknown user

begin transports

address_pipe:
  driver = pipe
  return_output

address_file:
  driver = appendfile
  delivery_date_add
  envelope_to_add
  return_path_add

remote_smtp:
  driver = smtp

local_delivery:
  driver = appendfile
  directory_mode = 700
  group = mail
  mode = 0660
  maildir_format = true
  directory = ${home}/Maildir/
  create_directory = true
  check_string = ""
  escape_string = ""
  mode_fail_narrower = false
  envelope_to_add = true

begin retry
# Address or Domain     Error      Retries
# -----------------     -----      -------
*                       *          F,5h,5m; G,16h,1h,1.5; F,4d,6h

begin authenticators

plain:
  driver           = plaintext
  public_name      = PLAIN
  server_condition = ${perl{login}{/etc/exim4/passwd.smtpd}{$2}{$3}}

login:
  driver           = plaintext
  public_name      = LOGIN
  server_prompts   = "Username:: : Password::"
  server_condition = ${perl{login}{/etc/exim4/passwd.smtpd}{$1}{$2}}
```

*/etc/exim4/smtpd_passwd_check.pl*
```perl
#!/usr/bin/perl

use Apache::Htpasswd;

sub login
{
  my $file = shift;
  my $account = shift;
  my $password = shift;

  if ( ! -r $file )
  {
    return 0;
  }

  $b = new Apache::Htpasswd({passwdFile => $file,
                             ReadOnly   => 1});

  if ($b->htCheckPassword($account, $password))
  {
    return 1;
  }
  else
  {
    return 0;
  }

}
```
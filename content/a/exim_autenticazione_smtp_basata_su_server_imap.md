+++
title = "Exim: autenticazione SMTP basata su server IMAP"
date = 2007-12-08
draft = false
tags = ["exim", "exim4", "perl", "imap", "smtp"]
+++
Creiamo subito il ﬁle */etc/exim/exim_perl.pl*:
```perl
#!/usr/bin/perl
use Net::IMAP::Simple;
sub imapLogin
{
  my $host = shift;
  my $account = shift;
  my $password = shift;
  # open a connection to the imap server
  if (! ($server = new Net::IMAP::Simple($host)))
  {
    return 0;
  }
  # login, if success return 1 (true) else 0 (false)
  if ($server->login( $account, $password ))
  {
    return 1;
  }
  else
  {
    return 0;
  }
  server->close();
}
```
E all'inizio della conﬁgurazione di **exim** inseriamo:
```
perl_startup = do '/etc/exim/exim_perl.pl'
perl_at_start
```
Mentre nella parte relativa all’autenticazione smtp inseriamo
```
begin  authenticators
plain:
  driver               =  plaintext
  public_name          =  PLAIN
  server_condition     =  ${perl{imapLogin}{localhost}{$2}{$3}}
  server_set_id        =  $2
login:
  driver               =  plaintext
  public_name          =  LOGIN
  server_prompts       =  "Username:: : Password::"
  server_condition     =  ${perl{imapLogin}{localhost}{$1}{$2}}
  server_set_id        =  $1
```
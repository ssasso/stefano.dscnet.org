#!/bin/bash

L=$1	# nome NetBios del server samba
U=$2	# nome utente
G=$3	# gruppo dell'utente
H=$4	# home dell'utente
u=$5	# nome dell'utente
S=$6	# nome del dominio
I=$7	# IP del client
m=$8	# nome NetBios del client
O=$9	# ON/OFF

# esce se dominio "IPC_"
[ $S == "IPC_" ] && exit
if [ ! -e $H ]; then
	mkdir -p "$H"
 	chown "$U":"$G" $H
	chmod 700 $H
fi

echo "$O	`date`	$u	\\\\$S	$I	$m" >> /var/log/samba/login-logoff/${L}_${I}_${u}.log


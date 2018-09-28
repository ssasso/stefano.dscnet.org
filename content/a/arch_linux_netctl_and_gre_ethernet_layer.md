+++
title = "Arch Linux, netctl and GRE Ethernet Layer"
date = 2013-08-06
draft = false
tags = ["arch", "ethernet", "gre", "gretap", "linux", "l2", "layer2", "netctl", "networking", "tunnel", "router"]
+++

## How to create GRE Ethernet (layer 2) with Arch Linux and netctl

under */usr/lib/network/connections* create file gretap with the following content:
```bash
# Contributed by: Stefano Sasso 

. "$SUBR_DIR/ip"

: ${BindsToInterfaces=}

gretap_up() {
    if is_interface "$Interface"; then
        report_error "Interface '$Interface' already exists"
        return 1
    else
        localStr=""
        if [[ -n "$Local" ]]; then
                localStr="local $Local"
        fi
        ip link add "$Interface" type gretap remote "$Remote" $localStr
    fi

    bring_interface_up "$Interface"
    ip_set
}

gretap_down() {
    ip_unset
    bring_interface_down "$Interface"
    ip link del "$Interface"
}
```

then, under */etc/netctl*, create profile file (example: gretap)
```
Description='GRE L2 ethernet tunnel'

After=('eth0')

Interface=greth0
Connection=gretap
Mode='gretap'
Remote='10.200.0.10'
#Local='192.168.177.198'

IP=static
Address=('172.18.43.17/24')
```
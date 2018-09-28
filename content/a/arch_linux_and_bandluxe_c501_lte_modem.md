+++
title = "Arch Linux and Bandluxe C501 LTE modem"
date = 2013-08-06
draft = false
tags = ["arch", "bandluxe", "c501", "chap", "linux", "lte", "modem", "netctl", "networking", "ppp", "router"]
+++

## Simple howto on how to use Bandluxe C501 LTE modem with Arch Linux and netctl
https://wiki.archlinux.org/index.php/Netctl
requirements: usb_modeswitch data download from http://www.draisberghof.de/usb_modeswitch/

copy usb_modeswitch data under */usr/share/usb_modeswitch/*

create file */usr/lib/network/connections/bandluxe_ppp* with:
```bash
# Contributed by Stefano Sasso 
# Based on Robbie Smith  3G modem with pppd script.

: ${PPPD:=pppd}
: ${InterfaceRoot=dev/}

quote_word() {
    set -- "${@//\\/\\\\}"
    printf '"%s"\n' "${@//\"/\\\"}"
}

bandluxe_ppp_up() {
    local cfg
    local chat

    mkdir -p "$STATE_DIR/blux_ppp.${Interface}.${Profile}/"
    chmod 700 "$STATE_DIR/blux_ppp.${Interface}.${Profile}/"
    cfg="$STATE_DIR/blux_ppp.${Interface}.${Profile}/options"
    chat="$STATE_DIR/blux_ppp.${Interface}.${Profile}/modem.chat"
    echo "linkname $(quote_word "${Profile}")" > "${cfg}"
    chmod 600 "${cfg}"
    echo > "${chat}"

    cat >> "${cfg}" << EOF
${Interface}
460800
idle 7200
lock
crtscts
modem
noipdefault
connect-delay 20000
nobsdcomp
novj
persist
maxfail 10
proxyarp
lcp-echo-interval 30
lcp-echo-failure 4
:192.0.2.100
ipcp-accept-local
ipcp-accept-remote

EOF

    # Debug pppd output separately from netcfg
    if is_yes "${PPPDebug:-yes}"; then
        echo "debug" >> "${cfg}"
    fi

    # Sets up route
    if is_yes "${DefaultRoute:-yes}"; then
        echo "defaultroute" >> "${cfg}"
    else
        echo "nodefaultroute" >> "${cfg}"
    fi
    if is_yes "${UsePeerDNS:-yes}"; then
        echo "usepeerdns" >> "${cfg}"
    fi

    # Writes username and password
    echo "noauth" >> "${cfg}"
    echo "hide-password" >> ${cfg}
    [[ -n ${User} ]] && echo "user $(quote_word "${User}")" >> "${cfg}"
    [[ -n ${Password} ]] && echo "password $(quote_word "${Password}")" >> "${cfg}"

    if [ -n "${Pin}" ]; then
        PinStr="'OK' 'AT+CPIN=\"${Pin}\"'"
    else
        PinStr="'OK' 'AT'"
    fi
    report_debug echo $PinStr

    # Now that we've got the ppp configuration set up, write the chat script
    cat >> "${chat}" << EOF
ABORT BUSY
ABORT 'NO CARRIER'
ABORT ERROR
REPORT CONNECT
TIMEOUT 10
"" "ATZ"
OK "ATQ0 V1 E1"
${PinStr}
OK 'AT+CGDCONT=1,"IP","${AccessPointName}"'
OK "ATD*99***1#"
TIMEOUT 30
CONNECT \c

EOF

    # Add the chat script line to the configuration
    echo "connect \"/usr/sbin/chat -V -f ${chat}\"" >> "${cfg}"

    if ! $PPPD file "${cfg}"; then
        rmdir "$STATE_DIR/blux_ppp.${Interface}.${Profile}/"
        report_error "Couldn't make pppd connection."
        return 1
    fi
}

bandluxe_ppp_down() {
    local cfg chat pidfile pid
    cfg="$STATE_DIR/blux_ppp.${Interface}.${Profile}/options"
    chat="$STATE_DIR/blux_ppp.${Interface}.${Profile}/modem.chat"
    pidfile="/var/run/ppp-${Profile}.pid"

    if [[ -e $pidfile ]]; then
        read pid < "$pidfile"
        [[ "$pid" ]] && kill "$pid"
    fi

    rm "${cfg}" "${chat}"
    rmdir "$STATE_DIR/blux_ppp.${Interface}.${Profile}/"
}
```

and then create netctl profile file */etc/netctl/LTE*:
```
Description='LTE connection'
Interface=ttyUSB0
Connection=bandluxe_ppp

#After=('eth0')
ExecUpPost="sleep 3 ; systemctl restart openntpd || true &"

# Debug pppd / chat output (separately from netctl)
PPPDebug=true

# Use default route provided by the peer (default: true)
DefaultRoute=true
# Use DNS provided by the peer (default: true)
UsePeerDNS=true

# The access point name you are connecting to
AccessPointName=apn4.mogw.net

# If your device has a PIN code, set it here. Defaults to None
#Pin=None
```

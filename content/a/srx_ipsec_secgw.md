+++
title = "Juniper SRX 3GPP SecGW"
date = 2021-06-10
draft = false
tags = ["ipsec", "ikev2", "juniper", "junos", "tunnel", "srx", "networking", "secgw", "3gpp"]
+++

## Introduction

I had to create a configuration for a Proof-of-Concept 3GPP SecGW (Security Gateway for Femtocell to Core IPSec) with Juniper vSRX.
In that case, the SRX SecGW is responsible for assigning a dynamic IP address to the IPSec endpoint using IKEv2 Configuration Payload.

Juniper documentation displays how to configure SRX for a SecGW with both X509 and PSK, but it delegates the IP Address allocation to an external Radius server.

On my configuration, however, I use a local IP Pool for address allocation.

## Implementation and Configuration

First of all, I had to generate a X509 Certificate/Key pair for the SecGW and the HeNBs (femtocells). I used the tools included in Strongswan to quickly create a CA and child certificates:
```
# Create CA key and certificate
$ pki --gen > caKey.der
$ pki --self --in caKey.der --dn "CN=CA, OU=CA, O=COMPANY, C=IT" --ca > caCert.der

# Create key and certificate for Juniper SRX
$ pki --gen > srxKey.der
$ pki --issue --in srxKey.der --type priv --cacert caCert.der --cakey caKey.der --dn "CN=SRX-SECGW, OU=srx_series, O=COMPANY, C=IT" --san srx_series > srxCert.der

# Create key and certificate for demo femtocell
$ pki --gen > femtoKey.der
$ pki --issue --in femtoKey.der --type priv --cacert caCert.der --cakey caKey.der --dn "CN=femto_01, OU=femto_cell, O=COMPANY, C=IT" --san femto_01 > femtoCert.der
```

Then, I had to import the CA certificate and the SRX certificate/key pair on the vSRX (commands in operational mode, files are copied using scp/sftp):
```
> request security pki ca-certificate load ca-profile juniper-ca filename caCert.cer
> request security pki local-certificate load certificate-id SRX-SECGW filename srxCert.der key srxKey.der

> show security pki ca-certificate detail
> show security pki local-certificate detail
```

NOTE: The *ca-profile* needs to be configured before loading the CA certificate with:
```
set security pki ca-profile juniper-ca ca-identity CA
set security pki ca-profile juniper-ca revocation-check disable
```

This is the relevant configuration I adopted:
```
set security pki ca-profile juniper-ca ca-identity CA
set security pki ca-profile juniper-ca revocation-check disable

set security ike proposal IKE_PROP authentication-method rsa-signatures
set security ike proposal IKE_PROP dh-group group5
set security ike proposal IKE_PROP authentication-algorithm sha1
set security ike proposal IKE_PROP encryption-algorithm aes-256-cbc

set security ike policy IKE_POL proposals IKE_PROP
set security ike policy IKE_POL certificate local-certificate SRX-SECGW

set security ike gateway 3GPP_GW ike-policy IKE_POL
set security ike gateway 3GPP_GW dynamic distinguished-name wildcard OU=femto_cell
set security ike gateway 3GPP_GW dynamic ike-user-type group-ike-id
set security ike gateway 3GPP_GW local-identity distinguished-name
set security ike gateway 3GPP_GW external-interface ge-0/0/1.3413
set security ike gateway 3GPP_GW aaa access-profile femtoap
set security ike gateway 3GPP_GW version v2-only

set security ipsec proposal IPSEC_PROP protocol esp
set security ipsec proposal IPSEC_PROP authentication-algorithm hmac-sha1-96
set security ipsec proposal IPSEC_PROP encryption-algorithm aes-256-cbc
set security ipsec proposal IPSEC_PROP lifetime-seconds 300

set security ipsec policy IPSEC_POL perfect-forward-secrecy keys group5
set security ipsec policy IPSEC_POL proposals IPSEC_PROP

set security ipsec vpn 3GPP_VPN bind-interface st0.99
set security ipsec vpn 3GPP_VPN ike gateway 3GPP_GW
set security ipsec vpn 3GPP_VPN ike proxy-identity local 10.250.0.0/16
set security ipsec vpn 3GPP_VPN ike proxy-identity remote 0.0.0.0/0
set security ipsec vpn 3GPP_VPN ike ipsec-policy IPSEC_POL

set interfaces st0 unit 99 multipoint
set interfaces st0 unit 99 family inet address 10.251.1.129/28

set access address-pool femtopool address-range low 10.251.1.130
set access address-pool femtopool address-range high 10.251.1.140
set access profile femtoap authentication-order none
set access profile femtoap address-assignment pool femtopool
```

NOTE: Unfortunately, the only Traffic Selector allowed in this configuration mode is the *proxy-identity* one. It's not possible to configure additional IKEv2 traffic selectors.

#!/bin/bash

# 1. Configures "default" vpn message-spool size to 10000MB
# 2. Adds Handy Road CA certificate

CLI_FILENAME="default-vpn-spool.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"

echo "
home
enable
configure
message-spool message-vpn default
max-spool-usage 10000

home
enable
configure
create ssl domain-certificate-authority handy-ca
certificate content \"-----BEGIN CERTIFICATE-----\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\x0A-----END CERTIFICATE-----\x0A\"

home
enable
configure
create message-vpn vpn-01
authentication basic auth-type internal
no dynamic-message-routing shutdown
no shutdown
exit

message-spool message-vpn vpn-01
max-spool-usage 10000
exit

client-profile default message-vpn vpn-01
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

client-username default message-vpn vpn-01
password default
no shutdown
exit

client-profile default message-vpn default
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

home
enable
configure
create message-vpn ${routername}
authentication basic auth-type internal
no shutdown
exit

message-spool message-vpn ${routername}
max-spool-usage 10000
exit

client-profile default message-vpn ${routername}
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

client-username default message-vpn ${routername}
no shutdown
exit" > "${CLI_DIRNAME}/${CLI_FILENAME}"


/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}



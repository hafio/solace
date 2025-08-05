#!/bin/bash

# 1. Configures "default" vpn message-spool size to 10000MB
# 2. Adds Handy Road CA certificate

CLI_FILENAME="show-dr-status.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"

if [[ "${HOSTNAME}" == "xps-ps-01" ]] || [[ "${HOSTNAME}" == "xps-ps-02" ]]; then
echo "
show config-sync database
show replication
show message-vpn * replication 
" > "${CLI_DIRNAME}/${CLI_FILENAME}"
fi

/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}

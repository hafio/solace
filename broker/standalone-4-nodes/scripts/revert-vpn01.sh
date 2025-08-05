#!/bin/bash

CLI_FILENAME="default-vpn-spool.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"


declare -A vpn_def_state=(
	[xps-ps-01]="standby"
	[xps-ps-02]="active"
)


if [[ "${HOSTNAME}" == "xps-ps-01" ]] || [[ "${HOSTNAME}" == "xps-ps-02" ]]; then
echo "
home
enable
configure
message-vpn vpn-01
replication state ${vpn_def_state[${HOSTNAME}]}

" > "${CLI_DIRNAME}/${CLI_FILENAME}"
fi

/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}



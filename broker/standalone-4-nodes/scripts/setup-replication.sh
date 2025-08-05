#!/bin/bash

CLI_FILENAME="default-vpn-spool.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"


declare -A brk_host=(
	[xps-ps-01]="xps-ps-02"
	[xps-ps-02]="xps-ps-01"
)
declare -A vpn_def_state=(
	[xps-ps-01]="active"
	[xps-ps-02]="standby"
)
declare -A vpn_vpn_state=(
	[xps-ps-01]="standby"
	[xps-ps-02]="active"
)
declare -A ldr_vpn_state=(
	[xps-ps-01]="default"
	[xps-ps-02]="vpn-01"
)


if [[ "${HOSTNAME}" == "xps-ps-01" ]] || [[ "${HOSTNAME}" == "xps-ps-02" ]]; then
echo "
home
enable
configure
replication mate virtual-router-name v:${brk_host[${HOSTNAME}]}
replication mate connect-via ${brk_host[${HOSTNAME}]}.proj-sol-cluster_default:55443 ssl
replication config-sync bridge authentication auth-scheme basic
no replication config-sync bridge compressed-data
replication config-sync bridge ssl
replication config-sync bridge ssl-server-certificate-validation validate-server-name
replication config-sync bridge ssl-server-certificate-validation max-certificate-chain-depth 3
replication config-sync bridge ssl-server-certificate-validation validate-certificate-date
no replication config-sync bridge shutdown

home
enable
configure
message-vpn default
replication bridge authentication basic client-username default password default
replication bridge ssl
!replication bridge unidirectional client-profile default
replication queue reject-msg-to-sender-on-discard
replication reject-msg-when-sync-ineligible
create replication replicated-topic \">\"
replication-mode async
exit
state ${vpn_def_state[${HOSTNAME}]}
no shutdown force-recreate-queue

home
enable
configure
message-vpn vpn-01
replication bridge authentication basic client-username default password default
replication bridge ssl
!replication bridge unidirectional client-profile default
replication queue reject-msg-to-sender-on-discard
replication reject-msg-when-sync-ineligible
create replication replicated-topic \">\"
replication-mode async
exit
state ${vpn_vpn_state[${HOSTNAME}]}
no shutdown force-recreate-queue

home
enable
admin
config-sync assert-leader message-vpn ${ldr_vpn_state[${HOSTNAME}]}
exit

configure
config-sync ssl
no config-sync shutdown

" > "${CLI_DIRNAME}/${CLI_FILENAME}"
fi

/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}



#!/bin/bash

source env.sh
broker=${broker:-ha-broker}
namespace=${namespace:-solace}

if [[ "$1" =~ ^[pbm]$ ]]; then
	node=$1
else
	echo Usage:
	echo "${0} [p|b|m]"
	echo "    [p]rimary or [b]ackup or [m]onitor"
	exit
fi

# winpty / conin is required to run certain interactive terminal commands
if type winpty >& /dev/null > /dev/null; then
	winpty=winpty
elif type conin >& /dev/null > /dev/null; then
	winpty=conin
fi

${winpty} kubectl exec -it ${broker}-pubsubplus-${node}-0 -n ${namespace} -- /usr/sw/loads/currentload/bin/cli -A
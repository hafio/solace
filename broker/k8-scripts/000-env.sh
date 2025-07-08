#!/bin/bash

while [[ $# -gt 0 ]]; do
	case "$1" in
		--env)
			ENV_FILE="$2"
			shift 2
			;;
		*)
			PARAMS="${PARAMS} $1"
			shift
			;;
	esac
done

EXDIR=`dirname $0`
ENV_FILE=${ENV_FILE:-default}
EXDIR=`dirname $0`
if [[ -f "${EXDIR}/env/${ENV_FILE}" ]]; then
	source "${EXDIR}/env/${ENV_FILE}"
else
	echo "Error: ${ENV_FILE} not found in '${EXDIR}/env' folder.

Usage: $0 --env <file>
	where <file> is a shell script that is used to capture the necessary variables used in deployment inside the 'env' directory.
	Default value is 'default'"
	exit 1
fi
set -- ${PARAMS}

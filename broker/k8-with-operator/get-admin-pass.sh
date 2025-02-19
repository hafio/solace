#!/bin/bash

source env.sh
broker=${broker:-ha-broker}
namespace=${namespace:-solace}

if [[ -z "${broker}" ]]; then
	broker=`kubectl get eventbroker -n solace -o jsonpath="{.items[0].metadata.name}"`
fi

secname=`kubectl get eventbroker ${broker} -n ${namespace} -o jsonpath="{.status.broker.adminCredentialsSecret}"`

kubectl get secret ${secname} -n ${namespace} -o jsonpath="{.data.username_admin_password}" | base64 -d
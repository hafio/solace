#!/bin/bash

source env.sh
broker=${broker:-ha-broker}
namespace=${namespace:-solace}

kubectl delete namespace ${namespace}
#echo "${yaml}" > .ha
#kubectl delete -f .ha
#rm -f .ha

echo kubectl delete pvc -n ${namespace} data-${broker}-pubsubplus-b-0
echo kubectl delete pvc -n ${namespace} data-${broker}-pubsubplus-m-0
echo kubectl delete pvc -n ${namespace} data-${broker}-pubsubplus-p-0

kubectl get pods,pvc -n ${namespace}
#!/bin/bash

source env.sh
broker=${broker:-ha-broker}
namespace=${namespace:-solace}

kubectl create namespace ${namespace}
echo "${yaml}" > .ha
kubectl apply -f .ha

#rm -f .ha

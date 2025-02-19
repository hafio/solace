#!/bin/bash

source env.sh
broker=${broker:-ha-broker}
namespace=${namespace:-solace}

kubectl create namespace ${namespace}
echo "apiVersion: pubsubplus.solace.com/v1beta1
kind: PubSubPlusEventBroker
metadata:
  name: ${broker}
  namespace: ${namespace}
spec:
  redundancy: true" > .ha

kubectl apply -f .ha

rm -f .ha

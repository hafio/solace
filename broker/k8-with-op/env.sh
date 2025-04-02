#!/bin/bash

broker=ha-broker
namespace=solace

yaml="apiVersion: pubsubplus.solace.com/v1beta1
kind: PubSubPlusEventBroker
metadata:
  name: ${broker}
  namespace: ${namespace}
spec:
  redundancy: true
  image:
    repository: solace-pubsub-enterprise
    tag: 10.8.1.209
#  containers:
#  - name: solace-broker-container
#    imagePullPolicy: Never # Never / IfNotPresent / Always
"
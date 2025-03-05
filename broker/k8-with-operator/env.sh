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
    repository: registry.hamaster.handy:45443/solace/pubsubplus/solace-ent
    tag: 10.8.1.209"
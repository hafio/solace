#!/bin/bash

####################################################################################################
# script to check instalaltion of Solace Operator. It does not do any indepth checks so use with caution
####################################################################################################

source env.sh

namespace=olm

kubectl get deployment olm-operator -n "${namespace}"
kubectl wait --for=condition=Established -f "${url}/crds.yaml"

kubectl rollout status -w deployment/olm-operator --namespace="${namespace}"
kubectl rollout status -w deployment/catalog-operator --namespace="${namespace}"
kubectl rollout status -w deployment/packageserver --namespace="${namespace}"

namespace=operators
kubectl rollout status deployment/pubsubplus-eventbroker-operator -n "${namespace}" -w
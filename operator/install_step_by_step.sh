#!/usr/bin/env bash

####################################################################################################
# this script has been edited from https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/install.sh to include all steps from https://operatorhub.io/operator/pubsubplus-eventbroker-operator and also to default the first position argument to 'v0.31.0'

echo "This script has been modified to include all Solace Operator installation steps and also defaulted installation version to v0.31.0"
echo "Please make sure v0.30.0 is the latest version - check script comments for URL reference"
read -p "Press any key to continue"

####################################################################################################

# This script is for installing OLM from a GitHub release

set -e


### hamlyn edit - added below lines to default first position argument to 'v0.31.0'
source env.sh

if kubectl get deployment olm-operator -n openshift-operator-lifecycle-manager > /dev/null 2>&1; then
    echo "OLM is already installed in a different configuration. This is common if you are not running a vanilla Kubernetes cluster. Exiting..."
    exit 1
fi

namespace=olm

if kubectl get deployment olm-operator -n ${namespace} > /dev/null 2>&1; then
    echo "OLM is already installed in ${namespace} namespace. Exiting..."
    exit 1
fi

kubectl create -f "${url}/crds.yaml" # https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/crds.yaml
kubectl wait --for=condition=Established -f "${url}/crds.yaml"
kubectl create -f "${url}/olm.yaml" # https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/olm.yaml

# wait for deployments to be ready
kubectl rollout status -w deployment/olm-operator --namespace="${namespace}"
kubectl rollout status -w deployment/catalog-operator --namespace="${namespace}"

# increased retries from 300 to 1000
retries=1000
until [[ $retries == 0 ]]; do
    new_csv_phase=$(kubectl get csv -n "${namespace}" packageserver -o jsonpath='{.status.phase}' 2>/dev/null || echo "Waiting for CSV to appear")
    if [[ $new_csv_phase != "$csv_phase" ]]; then
        csv_phase=$new_csv_phase
        echo "Package server phase: $csv_phase"
    fi
    if [[ "$new_csv_phase" == "Succeeded" ]]; then
	break
    fi
    sleep 10
    retries=$((retries - 1))
done

if [ $retries == 0 ]; then
    echo "CSV \"packageserver\" failed to reach phase succeeded"
    exit 1
fi

kubectl rollout status -w deployment/packageserver --namespace="${namespace}"

####################################################################################################
# hamlyn edit - added Step 2 and Step 3 from https://operatorhub.io/operator/pubsubplus-eventbroker-operator below
# Step 2: kubectl create -f https://operatorhub.io/install/pubsubplus-eventbroker-operator.yaml
# Step 3: kubectl get csv -n operators
#
# Also added loops and checks for each step
####################################################################################################

namespace=operators

if kubectl get deployment pubsubplus-eventbroker-operator -n ${namespace} > /dev/null 2>&1; then
    echo "Operator is already installed in ${namespace} namespace. Exiting..."
    exit 1
fi

if [[ -f "pubsubplus-eventbroker-operator.yaml" ]]; then
	kubectl create -f pubsubplus-eventbroker-operator.yaml
else
	kubectl create -f https://operatorhub.io/install/pubsubplus-eventbroker-operator.yaml
fi

echo "Waiting for pubsubplus-eventbroker-operator deployment"
retries=1000
until [[ $retries == 0 ]]; do
	if kubectl get deployment pubsubplus-eventbroker-operator -n ${namespace} > /dev/null 2>&1; then
		break
	fi
    sleep 10
    retries=$((retries - 1))
done

if [ $retries == 0 ]; then
    echo "Deployment \"pubsubplus-eventbroker-operator\" failed to start"
    exit 1
fi

kubectl rollout status deployment/pubsubplus-eventbroker-operator -n ${namespace} -w

kubectl get deployment -n olm
kubectl get deployment -n operators

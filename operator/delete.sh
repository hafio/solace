#!/bin/bash

source env.sh

kubectl delete all --all -n olm
kubectl delete all --all -n operators
kubectl delete -f ${url}/crds.yaml
kubectl delete -f ${url}/olm.yaml

kubectl get all -n olm
kubectl get all -n operators
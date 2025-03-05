#!/bin/bash

clusName=mk
nodes=4
cpu=2
mem=4096

existing=`minikube profile list -o json | grep "\"Name\":\"${clusName}\""`
[[ -n "${existing}" ]] && (
	echo "Minikube cluster \"${clusName}\" exists."
) || (
	minikube start -p ${clusName} --nodes ${nodes} --cpus ${cpu} --memory ${mem}
)

minikube addons enable metrics-server -p ${clusName}
minikube addons enable volumesnapshots -p ${clusName}
minikube addons enable csi-hostpath-driver -p ${clusName}

echo 'apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: sol-standard
provisioner: hostpath.csi.k8s.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer' > .sc.yaml

kubectl apply -f .sc.yaml
rm .sc.yaml

kubectl patch sc standard -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}"

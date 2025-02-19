@echo off

call env.bat

kubectl.exe delete all --all -n olm
kubectl.exe delete all --all -n operators
kubectl.exe delete -f %url%/crds.yaml
kubectl.exe delete -f %url%/olm.yaml

kubectl.exe get all -n olm
kubectl.exe get all -n operators
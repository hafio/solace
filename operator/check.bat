@echo off

rem ####################################################################################################
rem # script to check instalaltion of Solace Operator. It does not do any indepth checks so use with caution
rem ####################################################################################################

call env.bat

set namespace=olm

kubectl.exe get deployment olm-operator -n %namespace%
kubectl.exe wait --for=condition=Established -f "%url%/crds.yaml"

kubectl.exe rollout status -w deployment/olm-operator -n %namespace%
kubectl.exe rollout status -w deployment/catalog-operator -n %namespace%
kubectl.exe rollout status -w deployment/packageserver -n %namespace%

set namespace=operators

kubectl.exe rollout status deployment/pubsubplus-eventbroker-operator -n %namespace% -w
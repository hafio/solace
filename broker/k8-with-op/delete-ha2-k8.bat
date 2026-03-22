@echo off

set broker-type=ha2
call ..\k8-common\env.bat

rem kubectl.exe delete namespace %namespace%
(
echo apiVersion: pubsubplus.solace.com/v1beta1
echo kind: PubSubPlusEventBroker
echo metadata:
echo   name: %broker%
echo   namespace: %namespace%
echo spec:
echo   redundancy: true
) > .ha

kubectl.exe delete -f .ha

del .ha

kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-b-0
kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-m-0
kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-p-0

kubectl.exe get pods,pvc -n %namespace%
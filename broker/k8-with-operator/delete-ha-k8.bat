@echo off

set broker-name=ha-broker
set namespace=solace

kubectl.exe delete namespace %namespace%
(
echo apiVersion: pubsubplus.solace.com/v1beta1
echo kind: PubSubPlusEventBroker
echo metadata:
echo   name: %broker-name%
echo   namespace: %namespace%
echo spec:
echo   redundancy: true
) > .ha

rem kubectl.exe delete -f .ha

del .ha

kubectl.exe delete pvc -n %namespace% data-%broker-name%-pubsubplus-b-0
kubectl.exe delete pvc -n %namespace% data-%broker-name%-pubsubplus-m-0
kubectl.exe delete pvc -n %namespace% data-%broker-name%-pubsubplus-p-0
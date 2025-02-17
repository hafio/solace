@echo off

set broker-name=ha-broker
set namespace=solace

kubectl.exe create namespace %namespace%
(
echo apiVersion: pubsubplus.solace.com/v1beta1
echo kind: PubSubPlusEventBroker
echo metadata:
echo   name: %broker-name%
echo   namespace: %namespace%
echo spec:
echo   redundancy: true
) > .ha

kubectl.exe apply -f .ha

del .ha

@echo off

call env.bat

kubectl.exe create namespace %namespace%
(
echo apiVersion: pubsubplus.solace.com/v1beta1
echo kind: PubSubPlusEventBroker
echo metadata:
echo   name: %broker%
echo   namespace: %namespace%
echo spec:
echo   redundancy: true
) > .ha

kubectl.exe apply -f .ha

del .ha

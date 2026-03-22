@echo off

set broker-type=ha4
call ..\k8-common\env.bat

kubectl.exe create namespace %namespace%
(
echo apiVersion: pubsubplus.solace.com/v1beta1
echo kind: PubSubPlusEventBroker
echo metadata:
echo   name: %broker%
echo   namespace: %namespace%
echo spec:
echo   redundancy: true
echo   nodeAssignment:
echo     - name: Primary
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/name
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/instance
echo                 topologyKey: kubernetes.io/hostname
echo     - name: Backup
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/name
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/instance
echo                 topologyKey: kubernetes.io/hostname
echo     - name: Monitor
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/name
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 matchLabelKeys:
echo                 - app.kubernetes.io/instance
echo                 topologyKey: kubernetes.io/hostname
) > .ha

kubectl.exe apply -f .ha

del .ha

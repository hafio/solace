@echo off

set broker-type=ha3
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
echo   nodeAssignment:
echo     - name: Primary
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/name: pubsubpluseventbroker
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/instance: %broker%
echo                 topologyKey: kubernetes.io/hostname
echo     - name: Backup
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/name: pubsubpluseventbroker
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/instance: %broker%
echo                 topologyKey: kubernetes.io/hostname
echo     - name: Monitor
echo       spec:
echo         affinity:
echo           podAntiAffinity:
echo             preferredDuringSchedulingIgnoredDuringExecution:
echo             - weight: 25
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/name: pubsubpluseventbroker
echo                 topologyKey: kubernetes.io/hostname
echo             - weight: 50
echo               podAffinityTerm:
echo                 labelSelector:
echo                   matchLabels:
echo                     app.kubernetes.io/instance: %broker%
echo                 topologyKey: kubernetes.io/hostname
) > .ha

kubectl.exe delete -f .ha

del .ha

kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-b-0
kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-m-0
kubectl.exe delete pvc -n %namespace% data-%broker%-pubsubplus-p-0

kubectl.exe get pods,pvc -n %namespace%
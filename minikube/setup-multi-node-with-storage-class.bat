@echo off

set cluster-name=mk
set nodes=4
set cpu=2
set mem=4096

for /f %%i in ('minikube.exe profile list -o json') do set JSON=%%i
echo %JSON% | findstr /C:"\"Name\":\"mk\"" >nul
if %errorlevel% equ 0 (
    echo Minikube cluster "mk" exists.
) else (
	minikube.exe start -p %cluster-name% --nodes %nodes% --cpus %cpu% --memory %mem%
)

minikube addons enable metrics-server -p %cluster-name%
minikube addons enable volumesnapshots -p %cluster-name%
minikube addons enable csi-hostpath-driver -p %cluster-name%

(
echo apiVersion: storage.k8s.io/v1
echo kind: StorageClass
echo metadata:
echo   annotations:
echo     storageclass.kubernetes.io/is-default-class: "true"
echo   labels:
echo     addonmanager.kubernetes.io/mode: EnsureExists
echo   name: sol-standard
echo provisioner: hostpath.csi.k8s.io
echo reclaimPolicy: Delete
echo volumeBindingMode: WaitForFirstConsumer
) > .sc.yaml

kubectl.exe apply -f .sc.yaml
del .sc.yaml

kubectl.exe patch sc standard -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}"

@echo off

set /A wait_time=3

call env.bat
set /A retries=100

rem ####################################################################################################
rem # this script has been edited from https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/install.sh to include all steps from https://operatorhub.io/operator/pubsubplus-eventbroker-operator and also to default the first position argument to %release%

echo This script has been modified to include all Solace Operator installation steps and also defaulted installation version to %release%
echo Please make sure %release% is the latest version - check script comments for URL reference
pause

rem ####################################################################################################

set namespace=olm
echo Namespace: %namespace%
echo Installing catalog, olm, packageserver...

rem CHECK IF OLM-OPERATOR IS INSTALLED
kubectl.exe get deployment olm-operator -n %namespace% 2>nul
if %errorlevel% equ 0 (
	echo OLM is already installed in a different configuration. This is common if you are not running a vanilla Kubernetes cluster. Exiting...
	exit
) else (
	kubectl.exe create -f %url%/crds.yaml
	kubectl.exe wait --for=condition=Established -f %url%/crds.yaml
	kubectl.exe create -f %url%/olm.yaml
	kubectl.exe rollout status -w deployment/olm-operator -n %namespace%
	kubectl.exe rollout status -w deployment/catalog-operator -n %namespace%
)

set csv_phase=
set /A kretries=%retries%

rem LOOP TO ENSURE PACKAGESERVER IS FULLY INSTALLED
:pkg_loop
kubectl.exe get csv -n %namespace% packageserver -o jsonpath="{.status.phase}" > .phase 2>nul
set /p new_phase=<.phase

if NOT "%new_phase%"=="%csv_phase%" (
	set csv_phase=%new_phase%
	echo Package server phase: %new_phase%
)

if %new_phase%==Succeeded (
	goto :pkg_loop_break
)

set /A kretries-=1

if %kretries% gtr 0 (
	timeout /T %wait_time% /NOBREAK >nul
	goto :pkg_loop
)

if %kretries% equ 0 (
	echo CSV packageserver fail to reach "Succeeded" phase
	exit
)

rem FINAL COMAND TO DISPLAY PACKAGESERVER ROLLOUT STATUS
:pkg_loop_break
kubectl.exe rollout status -w deployment/packageserver -n %namespace%

del .phase

:loop_new
set namespace=operators
echo Namespace: %namespace%
echo Installing pubsubplus-eventbroker-operator

rem CHECK IF SOLACE OPERATOR IS INSTALLED
kubectl.exe get deployment pubsubplus-eventbroker-operator -n %namespace% -o jsonpath="{.metadata.name}" > .op 2>nul
set /p op_name=<.op

if "%op_name%"=="pubsubplus-eventbroker-operator" (
	echo Operator is already installed in %namespace%. Exiting...
	exit
) else (
	kubectl.exe create -f https://operatorhub.io/install/pubsubplus-eventbroker-operator.yaml
	echo Waiting for Operator Deployment to be created...
)

set /A kretries=%retries%

rem LOOP TO ENSURE SOLACE OPERATOR IS FULLY INSTALLED
:opr_loop
kubectl.exe get deployment pubsubplus-eventbroker-operator -n %namespace% -o jsonpath="{.metadata.name}" > .op 2>nul
set /p op_name=<.op
if "%op_name%"=="pubsubplus-eventbroker-operator" (
	goto :opr_loop_break
)
set /A kretries-=1

if %kretries% gtr 0 (
	timeout /T %wait_time% /NOBREAK >nul
	goto :opr_loop
)

if %kretries% equ 0 (
	echo Deployment pubsubplus-eventbroker-operator fail to start
	exit
)

:opr_loop_break
kubectl.exe rollout status -w deployment/pubsubplus-eventbroker-operator -n %namespace%

del .op

kubectl.exe get deployment -n olm
kubectl.exe get deployment -n operators

:cleanup
if exist .phase del .phase
if exist .op del .op

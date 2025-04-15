@echo off

call env.bat

if "%broker%"=="" (
	kubectl.exe get eventbroker -n solace -o jsonpath="{.items[0].metadata.name}" > .tmp
	set /p broker=<.tmp
)

kubectl.exe get eventbroker %broker% -n %namespace% -o jsonpath="{.status.broker.adminCredentialsSecret}" > .tmp
set /p secname=<.tmp

kubectl.exe get secret %secname% -n %namespace% -o jsonpath="{.data.username_admin_password}" > .tmp

certutil.exe -f -decode .tmp .out >nul
type .out

if exist .tmp del .tmp
if exist .out del .out
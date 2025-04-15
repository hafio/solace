@echo off

if NOT "%~1"=="ha" (
	if NOT "%~1"=="sa" (
		call %~dp0%env.bat
		kubectl.exe get eventbroker -n solace -o jsonpath="{.items[0].metadata.name}" > .tmp
		set /p broker=<.tmp
		goto :GETSECRET
	) else (
		goto :HASABROKER
	)
) else (
	goto :HASABROKER
)

:HASABROKER
set broker-type=%~1
call %~dp0%env.bat

:GETSECRET
kubectl.exe get eventbroker %broker% -n %namespace% -o jsonpath="{.status.broker.adminCredentialsSecret}" > .tmp
set /p secname=<.tmp

kubectl.exe get secret %secname% -n %namespace% -o jsonpath="{.data.username_admin_password}" > .tmp

certutil.exe -f -decode .tmp .out >nul
type .out

if exist .tmp del .tmp
if exist .out del .out
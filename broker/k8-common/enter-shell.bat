@echo off 

setlocal

if NOT "%~1"=="ha" (
	if NOT "%~1"=="sa" (
		goto :USAGE
) )

set broker-type=%~1
call env.bat

if "%~2"=="p" ( 
	set node=%~2
) else if "%~2"=="b" (
	set node=%~2
) else if "%~2"=="m" (
	set node=%~2
) else (
	goto :USAGE
) 

kubectl.exe exec -it %broker%-pubsubplus-%node%-0 -n %namespace% -- bash

exit

:USAGE
	echo.
	echo Usage:
	echo %~0 ^<ha^|sa^> ^<p^|b^|m^>
	echo     ^(p^)rimary or ^(b^)ackup or ^(m^)onitor
	echo.

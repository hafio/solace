@echo off 

setlocal

set broker-name=ha-broker
set namespace=solace

if "%1"=="p" ( 
	set node=%1
) else if "%1"=="b" (
	set node=%1
) else if "%1"=="m" (
	set node=%1
) else (
	echo Usage:
	echo %0 [p^|b^|m]
	echo     [p]rimary or [b]ackup or [m]onitor
	exit
) 

kubectl.exe exec -it %broker-name%-pubsubplus-%node%-0 -n %namespace% -- /usr/sw/loads/currentload/bin/cli -A
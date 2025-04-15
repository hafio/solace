@echo off

set broker=sol-broker
if NOT "%broker-type%" == "" (set broker=sol-%broker-type%-broker)
set namespace=solace

set kube-secret=lta-flip-tls
rem set cert-file=lta-server.crt
rem set key-file=lta-server.key

rem set kube-secret=ham-svr-tls
rem set cert-file=tls.crt
rem set key-file=tls.key
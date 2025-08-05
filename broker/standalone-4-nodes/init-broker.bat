@echo off

docker.exe exec xps-ps-01 /run/scripts/broker-init.sh
docker.exe exec xps-ps-02 /run/scripts/broker-init.sh
docker.exe exec xps-ps-03 /run/scripts/broker-init.sh
docker.exe exec xps-ps-04 /run/scripts/broker-init.sh


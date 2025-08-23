@echo off

docker.exe exec xps-ps-01 /run/scripts/%~1.sh
docker.exe exec xps-ps-02 /run/scripts/%~1.sh
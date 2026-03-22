@echo off

IF [%2]==[] (
  echo %0 ^<1-4^> ^<cli script name in /run/scripts^>
  exit /B 1
)
echo [%1] | findstr /R "\[[1-4]\]" >nul
IF %ERRORLEVEL% NEQ 0 (
  echo %0 ^<1-4^> ^<cli script name in /run/scripts^>
  exit /B 1
)
IF NOT EXIST scripts/%2 (
  echo scripts/%2 is not found
  exit /B 1
)

docker exec xps-ps-0%1 cp /run/scripts/%2 /usr/sw/jail/cliscripts/%2
docker exec xps-ps-0%1 /usr/sw/loads/currentload/bin/cli -Apes %2
docker exec xps-ps-0%1 rm /usr/sw/jail/cliscripts/%2
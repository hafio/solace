@echo off
setlocal

echo Checking Docker Desktop engine...

docker info >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Docker Desktop is running. Stopping Docker Desktop...

    REM Stop Docker backend processes
    taskkill /IM "Docker Desktop.exe" /F >nul 2>&1
    taskkill /IM "com.docker.backend.exe" /F >nul 2>&1
    taskkill /IM "vpnkit.exe" /F >nul 2>&1

    REM Shutdown WSL VM used by Docker
    wsl --shutdown >nul 2>&1

    echo Docker Desktop stopped.
) ELSE (
    echo Docker Desktop is not running.
)

echo Restarting WinNAT service...

net stop winnat >nul 2>&1
timeout /t 2 >nul
net start winnat >nul 2>&1

IF %ERRORLEVEL% EQU 0 (
    echo WinNAT restarted successfully.
) ELSE (
    echo Failed to restart WinNAT. Ensure script is run as Administrator.
)

echo Done.
endlocal

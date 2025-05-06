@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo       Combined Minikube Setup & Access (Windows)
echo =======================================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script needs to be run as Administrator!
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo --- Part 1: Basic Minikube Setup ---
echo.

REM Check if Minikube is running
echo Checking if Minikube is running...
minikube status >nul 2>&1
if %errorLevel% neq 0 (
    echo Starting Minikube...
    minikube start
) else (
    echo Minikube is already running.
)

REM Enable ingress addon if not already enabled
echo Checking ingress addon...
minikube addons list | findstr "ingress.*enabled" >nul 2>&1
if %errorLevel% neq 0 (
    echo Enabling ingress addon...
    minikube addons enable ingress
) else (
    echo Ingress addon is already enabled.
)

REM Get Minikube IP
for /f "tokens=*" %%i in ('minikube ip') do set MINIKUBE_IP=%%i
echo Minikube IP: %MINIKUBE_IP%

REM Update hosts file for minikube.local
set MINIKUBE_DOMAIN=minikube.local
echo Checking hosts file for %MINIKUBE_DOMAIN%...
findstr /c:"%MINIKUBE_DOMAIN%" %WINDIR%\System32\drivers\etc\hosts >nul
if %errorLevel% equ 0 (
    echo Entry for %MINIKUBE_DOMAIN% exists. Updating...
    powershell -Command "(Get-Content %WINDIR%\System32\drivers\etc\hosts) -replace '^.*%MINIKUBE_DOMAIN%.*$', '%MINIKUBE_IP% %MINIKUBE_DOMAIN%' | Set-Content %WINDIR%\System32\drivers\etc\hosts"
) else (
    echo Adding %MINIKUBE_DOMAIN% to hosts file...
    echo %MINIKUBE_IP% %MINIKUBE_DOMAIN% >> %WINDIR%\System32\drivers\etc\hosts
)
echo Hosts file updated for %MINIKUBE_DOMAIN%.

echo.
echo --- Part 2: Local Network Access Setup ---
echo.

echo Detecting your active network interface...
set LOCAL_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP:~1!
    echo Found IP: !IP!
    echo !IP! | findstr /r /c:"^192\.168\." /c:"^10\." /c:"^172\.[1-3][0-9]\." > nul
    if !errorLevel! equ 0 (
        echo This appears to be your local network IP.
        set LOCAL_IP=!IP!
        goto :found_local_ip
    )
)

:ip_input
echo.
echo Could not automatically detect your local network IP.
set /p LOCAL_IP="Please enter your local network IP address (e.g., 192.168.1.100): "
if "%LOCAL_IP%"=="" goto ip_input

:found_local_ip
echo.
echo Using Local Network IP: %LOCAL_IP%
echo.

REM Update hosts file for custom domain
set ACCESS_DOMAIN=1ex.hire.roie.local
echo Setting up hosts file for %ACCESS_DOMAIN%...
findstr /c:"%ACCESS_DOMAIN%" %WINDIR%\System32\drivers\etc\hosts > nul
if %errorLevel% equ 0 (
    echo Entry for %ACCESS_DOMAIN% exists. Updating...
    powershell -Command "(Get-Content %WINDIR%\System32\drivers\etc\hosts) -replace '^.*%ACCESS_DOMAIN%.*$', '%LOCAL_IP% %ACCESS_DOMAIN%' | Set-Content %WINDIR%\System32\drivers\etc\hosts"
) else (
    echo Adding %ACCESS_DOMAIN% to hosts file...
    echo %LOCAL_IP% %ACCESS_DOMAIN% >> %WINDIR%\System32\drivers\etc\hosts
)
echo Hosts file updated for %ACCESS_DOMAIN%.

echo.
echo --- Part 3: Start Tunnel (Manual Step) ---
echo.
echo To access the application from other devices on your network (using http://%ACCESS_DOMAIN%/),
echo you MUST run the following command in a SEPARATE terminal and keep it running:
echo.
echo   minikube tunnel --bind-address=%LOCAL_IP%
echo.
echo Make sure you use the IP address: %LOCAL_IP%
echo.

echo ==========================================================
echo Setup Complete!
echo.
echo - For basic access (from this machine only): http://%MINIKUBE_DOMAIN%/
echo   (Requires 'minikube tunnel' if service type is LoadBalancer)
echo.
echo - For access from your local network: http://%ACCESS_DOMAIN%/
echo   (Requires the tunnel command above to be running)
echo.
echo Remember:
echo 1. You may need to flush DNS cache ('ipconfig /flushdns')
echo 2. Try restarting your browser if a site doesn't load
echo ==========================================================
echo.

pause
exit /b 0

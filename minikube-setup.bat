@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo       Setting up Minikube for local deployment
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

REM Update hosts file
echo Checking if minikube.local exists in hosts file...
findstr /c:"minikube.local" %WINDIR%\System32\drivers\etc\hosts >nul
if %errorLevel% equ 0 (
    echo Entry for minikube.local already exists in hosts file. Updating...
    powershell -Command "(Get-Content %WINDIR%\System32\drivers\etc\hosts) -replace '^.*minikube\.local.*$', '%MINIKUBE_IP% minikube.local' | Set-Content %WINDIR%\System32\drivers\etc\hosts"
) else (
    echo Adding minikube.local to hosts file...
    echo %MINIKUBE_IP% minikube.local >> %WINDIR%\System32\drivers\etc\hosts
)

echo.
echo Minikube environment is ready!
echo You can now run 'make minikube-cd' to deploy the application.
echo.

pause
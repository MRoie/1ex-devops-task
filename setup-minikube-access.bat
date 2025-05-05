@echo off
setlocal

echo ======================================================
echo     Minikube Local Access Setup Wizard
echo ======================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script needs to be run as Administrator!
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Detecting your active network interface...
echo.

REM Get list of active IP addresses
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP:~1!
    echo Found IP: !IP!
    
    REM Skip localhost or virtual adapters
    echo !IP! | findstr /r /c:"^192\.168\." /c:"^10\." /c:"^172\.[1-3][0-9]\." > nul
    if !errorLevel! equ 0 (
        echo This appears to be your local network IP.
        set LOCAL_IP=!IP!
        goto :found_ip
    )
)

:ip_input
echo.
echo Could not automatically detect your local network IP.
set /p LOCAL_IP="Please enter your local network IP address: "

:found_ip
echo.
echo Will use IP: %LOCAL_IP%
echo.

REM Ask for domain
set DOMAIN=1ex.hire.roie.local
echo Using domain: %DOMAIN%
echo.

echo Setting up hosts file...
findstr /c:"%DOMAIN%" %WINDIR%\System32\drivers\etc\hosts > nul
if %errorLevel% equ 0 (
    echo Entry for %DOMAIN% already exists in hosts file. Updating...
    powershell -Command "(Get-Content %WINDIR%\System32\drivers\etc\hosts) -replace '^.*%DOMAIN%.*$', '%LOCAL_IP% %DOMAIN%' | Set-Content %WINDIR%\System32\drivers\etc\hosts"
) else (
    echo %LOCAL_IP% %DOMAIN% >> %WINDIR%\System32\drivers\etc\hosts
)

echo Checking if Minikube is running...
minikube status > nul
if %errorLevel% neq 0 (
    echo Starting Minikube...
    minikube start
) else (
    echo Minikube is already running.
)

echo Checking if ingress addon is enabled...
minikube addons list | findstr "ingress.*enabled" > nul
if %errorLevel% neq 0 (
    echo Enabling ingress addon...
    minikube addons enable ingress
) else (
    echo Ingress addon is already enabled.
)

echo.
echo Starting Minikube tunnel with bind address %LOCAL_IP%...
echo This will open a new command window. DO NOT CLOSE IT while using the application.
echo.
echo Press any key to start the tunnel...
pause > nul

start "Minikube Tunnel" cmd /k "echo Running Minikube tunnel bound to %LOCAL_IP% & echo. & echo DO NOT CLOSE THIS WINDOW while using the application & echo. & minikube tunnel --bind-address=%LOCAL_IP%"

echo.
echo ==========================================================
echo Setup complete! Your app should now be accessible at:
echo http://%DOMAIN%/
echo.
echo Remember:
echo 1. The tunnel must remain running in the other window
echo 2. You may need to flush DNS cache with 'ipconfig /flushdns'
echo 3. Try restarting your browser if the site doesn't load
echo ==========================================================
echo.

pause
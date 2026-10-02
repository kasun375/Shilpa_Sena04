@echo off
title Shilpa Sena Web App Launcher
echo ========================================================
echo   Starting Shilpa Sena LMS Web Application...
echo ========================================================
echo.

cd /d "%~dp0Shilpa_Sena\webapp"

:: Launch browser after 2 second delay to ensure server is ready
start "" cmd /c "ping 127.0.0.1 -n 3 >nul && start http://localhost:8080"

echo Server starting on http://localhost:8080 ...
echo (Keep this terminal window open while using the Web App)
echo.

python -m http.server 8080
if %errorlevel% neq 0 (
    echo.
    echo Port 8080 might be in use or python command failed.
    echo Launching server on fallback port 8085...
    start "" cmd /c "ping 127.0.0.1 -n 3 >nul && start http://localhost:8085"
    python -m http.server 8085
    if %errorlevel% neq 0 (
        py -m http.server 8085
    )
)

pause

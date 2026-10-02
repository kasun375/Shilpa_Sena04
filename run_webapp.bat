@echo off
title Shilpa Sena Web App Server
echo ========================================================
echo   Starting Shilpa Sena LMS Web Application...
echo ========================================================
echo.

cd /d "%~dp0Shilpa_Sena\webapp"

:: Launch browser after 2 second delay to ensure server is listening
start "" cmd /c "ping 127.0.0.1 -n 3 >nul && start http://localhost:8080"

echo Server running on http://localhost:8080 (Keep this window open)
echo.

python -m http.server 8080
if %errorlevel% neq 0 (
    echo Python command failed, trying py launcher...
    py -m http.server 8080
)

pause

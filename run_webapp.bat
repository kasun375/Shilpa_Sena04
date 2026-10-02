@echo off
title Shilpa Sena Web App Server
echo ========================================================
echo   Starting Shilpa Sena LMS Web Application...
echo ========================================================
echo.

cd /d "%~dp0Shilpa_Sena\webapp"

echo Launching Web Browser at http://localhost:8080 ...
start "" cmd /c "timeout /t 2 /nobreak >nul & start http://localhost:8080"

echo.
echo Server running on http://localhost:8080 (Press Ctrl+C to stop)
echo.
python -m http.server 8080
pause


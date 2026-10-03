@echo off
title Shilpa Sena Web App Launcher
echo ========================================================
echo   Starting Shilpa Sena LMS Web Application...
echo ========================================================
echo.

WHERE node >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
    echo Launching Node.js Full-Stack Server (Web App + Payment Backend)...
    cd /d "%~dp0Shilpa_Sena\server"
    start "" cmd /c "ping 127.0.0.1 -n 3 >nul && start http://localhost:3000"
    echo Server starting on http://localhost:3000 ...
    echo (Keep this terminal window open while using the Web App)
    echo.
    node server.js
    if %errorlevel% neq 0 (
        goto fallback_python
    )
) ELSE (
    goto fallback_python
)

goto end

:fallback_python
echo Node.js not detected or failed. Launching Static Python Web Server...
cd /d "%~dp0Shilpa_Sena\webapp"
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

:end
pause


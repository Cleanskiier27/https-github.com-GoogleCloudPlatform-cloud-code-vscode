@echo off
REM NetworkBuster Multi-Server Launch Script
REM Launches backend, proxy, and frontend in separate windows

setlocal enabledelayedexpansion
set "WORKSPACE=%~dp0"
cd /d "%WORKSPACE%"

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  NetworkBuster Multi-Server Launcher                       ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  Starting all services on network 192.168.1.180            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js not found! Please install Node.js first.
    pause
    exit /b 1
)

echo ✓ Node.js detected
echo.

REM Validate npm packages
if not exist "node_modules" (
    echo 📦 Installing dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
)

echo.
echo 🚀 Launching services...
echo.

REM Terminal 1: Backend Server (3001)
echo [1/3] Starting Backend Server on port 3001...
start "NetworkBuster Backend (3001)" cmd /k "cd /d %WORKSPACE% && npm start"
timeout /t 3 /nobreak

REM Terminal 2: Network Proxy (3000)
echo [2/3] Starting Network Proxy on port 3000...
start "NetworkBuster Proxy (3000→3001)" cmd /k "cd /d %WORKSPACE% && set PROXY_PORT=3000 && node proxy-server.js"
timeout /t 2 /nobreak

REM Terminal 3: Frontend Dev Server (5173)
echo [3/3] Starting Frontend Dev Server on port 5173...
start "NetworkBuster Frontend (5173)" cmd /k "cd /d %WORKSPACE% && npm run dev"
timeout /t 2 /nobreak

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  ✓ All services launched!                                  ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  Frontend:        http://192.168.1.180:5173                ║
echo ║  Network Proxy:   http://192.168.1.180:3000                ║
echo ║  Backend API:     http://192.168.1.180:3001                ║
echo ║  Control Panel:   http://192.168.1.180:3001/control-panel  ║
echo ║  Dashboard:       http://192.168.1.180:3001/dashboard      ║
echo ║  Overlay:         http://192.168.1.180:3001/overlay        ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 💡 Open separate terminals are running. Close them to stop services.
echo.
pause

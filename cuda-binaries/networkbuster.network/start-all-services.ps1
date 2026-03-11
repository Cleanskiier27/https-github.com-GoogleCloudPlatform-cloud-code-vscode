# NetworkBuster Multi-Server Launch Script (PowerShell)
# Launches backend, proxy, and frontend in separate PowerShell windows

param(
    [string]$ProxyPort = "3000",
    [switch]$NoFrontend,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
NetworkBuster Multi-Server Launcher

Usage:
  .\start-all-services.ps1 [-ProxyPort <port>] [-NoFrontend] [-Help]

Options:
  -ProxyPort     Port for network proxy (default: 3000)
  -NoFrontend    Don't start frontend dev server
  -Help          Show this help message

Examples:
  # Start all services with proxy on port 3000
  .\start-all-services.ps1

  # Start with proxy on port 8080
  .\start-all-services.ps1 -ProxyPort 8080

  # Start only backend and proxy (no frontend)
  .\start-all-services.ps1 -NoFrontend

"@
    exit 0
}

# Colors
$HeaderColor = 'Cyan'
$SuccessColor = 'Green'
$WarningColor = 'Yellow'
$ErrorColor = 'Red'

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $HeaderColor
Write-Host "║  NetworkBuster Multi-Server Launcher (PowerShell)          ║" -ForegroundColor $HeaderColor
Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor $HeaderColor
Write-Host "║  Starting all services on network 192.168.1.180            ║" -ForegroundColor $HeaderColor
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $HeaderColor
Write-Host ""

# Check Node.js
Write-Host "Checking prerequisites..." -ForegroundColor $WarningColor
$NodeTest = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeTest) {
    Write-Host "❌ Node.js not found! Please install Node.js first." -ForegroundColor $ErrorColor
    exit 1
}
Write-Host "✓ Node.js detected" -ForegroundColor $SuccessColor
Write-Host ""

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor $WarningColor
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor $ErrorColor
        exit 1
    }
}

Write-Host ""
Write-Host "🚀 Launching services..." -ForegroundColor $SuccessColor
Write-Host ""

# Terminal 1: Backend Server (3001)
Write-Host "[1/3] Starting Backend Server on port 3001..." -ForegroundColor $WarningColor
$BackendParams = @{
    FilePath = "pwsh.exe"
    ArgumentList = @("-NoExit", "-Command", "cd '$PWD'; npm start")
    WindowStyle = "Normal"
}
Start-Process @BackendParams
Start-Sleep -Seconds 3

# Terminal 2: Network Proxy
Write-Host "[2/3] Starting Network Proxy on port $ProxyPort..." -ForegroundColor $WarningColor
$ProxyParams = @{
    FilePath = "pwsh.exe"
    ArgumentList = @(
        "-NoExit", 
        "-Command", 
        "`$env:PROXY_PORT='$ProxyPort'; cd '$PWD'; node proxy-server.js"
    )
    WindowStyle = "Normal"
}
Start-Process @ProxyParams
Start-Sleep -Seconds 2

# Terminal 3: Frontend Dev Server (optional)
if (-not $NoFrontend) {
    Write-Host "[3/3] Starting Frontend Dev Server on port 5173..." -ForegroundColor $WarningColor
    $FrontendParams = @{
        FilePath = "pwsh.exe"
        ArgumentList = @("-NoExit", "-Command", "cd '$PWD'; npm run dev")
        WindowStyle = "Normal"
    }
    Start-Process @FrontendParams
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $HeaderColor
Write-Host "║  ✓ All services launched!                                  ║" -ForegroundColor $HeaderColor
Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor $HeaderColor
Write-Host "║  Frontend:        http://192.168.1.180:5173                ║" -ForegroundColor $SuccessColor
Write-Host "║  Network Proxy:   http://192.168.1.180:$ProxyPort                ║" -ForegroundColor $SuccessColor
Write-Host "║  Backend API:     http://192.168.1.180:3001                ║" -ForegroundColor $SuccessColor
Write-Host "║  Control Panel:   http://192.168.1.180:3001/control-panel  ║" -ForegroundColor $SuccessColor
Write-Host "║  Dashboard:       http://192.168.1.180:3001/dashboard      ║" -ForegroundColor $SuccessColor
Write-Host "║  Overlay:         http://192.168.1.180:3001/overlay        ║" -ForegroundColor $SuccessColor
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $HeaderColor
Write-Host ""
Write-Host "💡 Separate PowerShell windows are running. Close them to stop services." -ForegroundColor $WarningColor
Write-Host "📖 For more info, see NETWORK_PROXY_GUIDE.md" -ForegroundColor $WarningColor
Write-Host ""

# Keep this window open
Read-Host "Press Enter to exit launcher (services continue running)"

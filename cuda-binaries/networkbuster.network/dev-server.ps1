#requires -Version 5.1
<#
.SYNOPSIS
    NetworkBuster Unified Development Environment
    
.DESCRIPTION
    Starts both Express backend and Vite frontend servers
    with automatic hot module replacement and API proxying.
    
.EXAMPLE
    .\dev-server.ps1
#>

param()

$ErrorActionPreference = "Stop"

# Configuration
$BackendPort = 3000
$FrontendPort = 5173
$BackendUrl = "http://localhost:$BackendPort"
$FrontendUrl = "http://localhost:$FrontendPort"

# Helper functions
function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ NetworkBuster Unified Dev Environment ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Status = "Info")
    
    $colors = @{
        Info = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
    }
    
    $symbol = @{
        Info = "ℹ"
        Success = "✓"
        Warning = "⚠"
        Error = "✗"
    }
    
    Write-Host "$($symbol[$Status]) $Message" -ForegroundColor $colors[$Status]
}

function Show-Setup-Info {
    Write-Status "Development Setup Configuration" "Info"
    Write-Host ""
    Write-Host "Backend (Express):   $BackendUrl" -ForegroundColor Green
    Write-Host "Frontend (Vite):     $FrontendUrl" -ForegroundColor Blue
    Write-Host "API Proxy:           Configured" -ForegroundColor Green
    Write-Host "Hot Reload:          Enabled" -ForegroundColor Green
    Write-Host ""
    Write-Status "Available Routes" "Info"
    Write-Host "  /              → Home Hub" -ForegroundColor Yellow
    Write-Host "  /home          → Navigation Hub" -ForegroundColor Yellow
    Write-Host "  /ai-world      → AI World Environment" -ForegroundColor Yellow
    Write-Host "  /dashboard     → Dashboard" -ForegroundColor Yellow
    Write-Host "  /control-panel → Control Panel" -ForegroundColor Yellow
    Write-Host "  /overlay       → Real-time Overlay" -ForegroundColor Yellow
    Write-Host "  /blog          → Blog" -ForegroundColor Yellow
    Write-Host "  /api/*         → API Endpoints" -ForegroundColor Yellow
    Write-Host ""
    Write-Status "Press Ctrl+C to stop all servers" "Success"
    Write-Host ""
}

function Start-Unified-Dev {
    Write-Header
    Show-Setup-Info
    
    # Start Express backend
    Write-Status "Starting Express backend server..." "Info"
    $backendJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        npm start
    }
    
    # Wait for backend to initialize
    Start-Sleep -Seconds 3
    
    # Start Vite frontend
    Write-Status "Starting Vite frontend development server..." "Info"
    $frontendJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        npm run dev:vite
    }
    
    Write-Status "Both servers started successfully" "Success"
    Write-Host ""
    
    # Keep running until interrupted
    try {
        while ($true) {
            $backendState = $backendJob.State
            $frontendState = $frontendJob.State
            
            if ($backendState -eq "Failed" -or $frontendState -eq "Failed") {
                Write-Status "One of the servers has stopped" "Error"
                break
            }
            
            Start-Sleep -Seconds 5
        }
    } finally {
        Write-Status "Shutting down development servers..." "Warning"
        Stop-Job -Job $backendJob, $frontendJob
        Remove-Job -Job $backendJob, $frontendJob
        Write-Status "Development environment stopped" "Success"
    }
}

# Main execution
Start-Unified-Dev

# SSH Agent Setup for Windows PowerShell
# This script initializes SSH agent and loads your SSH keys

function Start-SSHAgent {
    # Check if SSH Agent service exists
    $sshService = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
    
    if ($null -eq $sshService) {
        Write-Host "SSH Agent service not found." -ForegroundColor Yellow
        return
    }
    
    # Start SSH Agent service if not running
    if ($sshService.Status -ne 'Running') {
        Write-Host "Starting SSH Agent service..." -ForegroundColor Cyan
        Start-Service ssh-agent
        Set-Service -Name ssh-agent -StartupType Automatic
    }
    
    # Check if SSH keys are loaded
    $sshKeys = ssh-add -l 2>$null
    
    if ($LASTEXITCODE -eq 1) {
        Write-Host "Loading SSH keys..." -ForegroundColor Cyan
        $keyPath = "$env:USERPROFILE\.ssh\id_rsa"
        if (Test-Path $keyPath) {
            ssh-add $keyPath
            Write-Host "SSH key loaded successfully" -ForegroundColor Green
        } else {
            Write-Host "SSH key not found at $keyPath" -ForegroundColor Yellow
        }
    } elseif ($LASTEXITCODE -eq 2) {
        Write-Host "SSH Agent is not running" -ForegroundColor Red
    } else {
        Write-Host "SSH Agent is running with keys loaded:" -ForegroundColor Green
        ssh-add -l
    }
}

function New-SSHKey {
    param(
        [string]$KeyPath = "$env:USERPROFILE\.ssh\id_rsa",
        [string]$Email = "your-email@example.com",
        [int]$KeyBits = 4096
    )
    
    if (Test-Path $KeyPath) {
        Write-Host "SSH key already exists at $KeyPath" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Creating new SSH key..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b $KeyBits -f $KeyPath -N "" -C $Email
    
    Write-Host "SSH key created successfully" -ForegroundColor Green
}

function Show-SSHPublicKey {
    param(
        [string]$KeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
    )
    
    if (-not (Test-Path $KeyPath)) {
        Write-Host "SSH public key not found at $KeyPath" -ForegroundColor Red
        return
    }
    
    Write-Host "SSH Public Key (copy this to GitHub):" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Get-Content $KeyPath
    Write-Host "=====================================" -ForegroundColor Cyan
}

# Auto-start SSH Agent
Start-SSHAgent

#!/usr/bin/env powershell
<#
.SYNOPSIS
NetworkBuster - Cloud Storage Mount & Sync Manager
Import/Export between C: Desktop and D: Cloud Storage

.DESCRIPTION
- Manages permissions for D: cloud mount
- Imports files from D: to project
- Exports project data to D:
- Syncs configurations and backups
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('init', 'import', 'export', 'sync', 'backup', 'restore', 'status', 'attach-pfx', 'create-pfx')]
    [string]$Action = 'status'
)

$projectPath = "C:\Users\daypi\OneDrive\Desktop\networkbuster.net"
$cloudPath = "D:\networkbuster-cloud"
$backupPath = "$cloudPath\backups"
$importPath = "$cloudPath\imports"
$exportPath = "$cloudPath\exports"
$certificatePath = "$cloudPath\certificates"
$defaultPfxSource = 'C:\Users\daypi\Downloads\daypirate2\.codeoss\cli\networkbustersetup.pfx'

Write-Host @"
╔════════════════════════════════════════════════════════════╗
║  NetworkBuster Cloud Storage Manager                       ║
║  C: Desktop <-> D: Cloud Sync Utility                      ║
╚════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Initialize cloud structure
function Initialize-CloudStorage {
    Write-Host "`n[INIT] Setting up cloud storage structure..." -ForegroundColor Yellow
    
    $dirs = @($cloudPath, $backupPath, $importPath, $exportPath, $certificatePath)
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  [OK] Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "  [EXISTS] $dir" -ForegroundColor Gray
        }
    }
    
    # Set permissions (allow full access to current user)
    Write-Host "`n[PERMISSIONS] Setting access rights..." -ForegroundColor Yellow
    
    foreach ($dir in $dirs) {
        try {
            $acl = Get-Acl $dir
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
                [System.Security.AccessControl.FileSystemRights]::FullControl,
                [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $acl.SetAccessRule($rule)
            Set-Acl -Path $dir -AclObject $acl
            Write-Host "  [OK] Permissions set: $dir" -ForegroundColor Green
        } catch {
            Write-Host "  [WARNING] Could not modify ACL: $_" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n[SUCCESS] Cloud storage initialized!" -ForegroundColor Green
}

function New-RandomPassword {
    param(
        [int]$Length = 32
    )

    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%_-+=' 
    $bytes = New-Object byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
}

function Write-CertificateManifest {
    param(
        [string]$OutputPath,
        [string]$PasswordPath,
        [string]$Subject,
        [string]$Thumbprint,
        [string]$DnsName,
        [string]$Password
    )

    $manifest = @{
        timestamp = Get-Date -Format 'o'
        subject = $Subject
        thumbprint = $Thumbprint
        dnsName = $DnsName
        pfxPath = $OutputPath
        passwordPath = $PasswordPath
        purpose = 'User-controlled certificate for NetworkBuster deployment'
    } | ConvertTo-Json

    $manifestPath = Join-Path $certificatePath 'networkbustersetup.manifest.json'
    $manifest | Out-File -FilePath $manifestPath -Force
    $Password | Set-Content -Path $PasswordPath -Force

    Write-Host "  [OK] Manifest written: $manifestPath" -ForegroundColor Green
    Write-Host "  [OK] Password written: $PasswordPath" -ForegroundColor Green
}

function Test-ControlledPfx {
    param(
        [string]$PfxPath
    )

    $manifestPath = [System.IO.Path]::ChangeExtension($PfxPath, '.manifest.json')
    $passwordPath = [System.IO.Path]::ChangeExtension($PfxPath, '.password.txt')

    if (-not (Test-Path $manifestPath) -or -not (Test-Path $passwordPath)) {
        return $false
    }

    try {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
    } catch {
        return $false
    }

    return $manifest.purpose -eq 'User-controlled certificate for NetworkBuster deployment'
}

function New-ControlledPfx {
    param(
        [string]$OutputPath = (Join-Path $certificatePath 'networkbustersetup.pfx'),
        [string]$DnsName = 'networkbuster.local',
        [string]$Subject = 'CN=NetworkBuster Setup',
        [string]$Password
    )

    if (-not $Password) {
        $Password = New-RandomPassword
    }

    if (-not (Test-Path $certificatePath)) {
        New-Item -ItemType Directory -Path $certificatePath -Force | Out-Null
    }

    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $certificate = New-SelfSignedCertificate -Subject $Subject -DnsName $DnsName -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'NetworkBuster Setup Certificate' -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddYears(2) -HashAlgorithm 'SHA256'

    Export-PfxCertificate -Cert $certificate -FilePath $OutputPath -Password $securePassword -Force | Out-Null

    $passwordPath = [System.IO.Path]::ChangeExtension($OutputPath, '.password.txt')
    Write-CertificateManifest -OutputPath $OutputPath -PasswordPath $passwordPath -Subject $Subject -Thumbprint $certificate.Thumbprint -DnsName $DnsName -Password $Password

    Write-Host "  [OK] Created self-signed certificate: $($certificate.Thumbprint)" -ForegroundColor Green
    Write-Host "  [OK] Exported PFX: $OutputPath" -ForegroundColor Green
}

# Import from cloud
function Import-FromCloud {
    Write-Host "`n[IMPORT] Importing files from D: cloud storage..." -ForegroundColor Yellow
    
    if (-not (Test-Path $importPath)) {
        Write-Host "  [ERROR] Import folder not found: $importPath" -ForegroundColor Red
        return
    }
    
    $files = Get-ChildItem -Path $importPath -Recurse -File
    
    if ($files.Count -eq 0) {
        Write-Host "  [INFO] No files to import" -ForegroundColor Gray
        return
    }
    
    Write-Host "  [INFO] Found $($files.Count) file(s) to import" -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $destPath = $file.FullName.Replace($importPath, $projectPath)
        $destDir = Split-Path $destPath
        
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        Write-Host "  [OK] Imported: $($file.Name)" -ForegroundColor Green
    }
    
    # Archive imported files
    $archiveName = "imported_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $archivePath = "$cloudPath\imports-archive\$archiveName"
    
    Write-Host "`n[ARCHIVE] Creating archive of imported files..." -ForegroundColor Yellow
    Compress-Archive -Path $importPath -DestinationPath $archivePath -Force
    Write-Host "  [OK] Archive created: $archivePath" -ForegroundColor Green
    
    # Clear import folder
    Remove-Item -Path $importPath\* -Force -Recurse
    Write-Host "  [OK] Import folder cleared" -ForegroundColor Green
}

# Export to cloud
function Export-ToCloud {
    Write-Host "`n[EXPORT] Exporting project data to D: cloud storage..." -ForegroundColor Yellow
    
    $itemsToExport = @(
        'package.json',
        'package-lock.json',
        'auth-ui',
        'api',
        'docs',
        'data',
        'infra'
    )
    
    foreach ($item in $itemsToExport) {
        $sourcePath = Join-Path $projectPath $item
        $destPath = Join-Path $exportPath (Split-Path $sourcePath -Leaf)
        
        if (Test-Path $sourcePath) {
            if ((Get-Item $sourcePath).PSIsContainer) {
                Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
                Write-Host "  [OK] Exported folder: $item" -ForegroundColor Green
            } else {
                Copy-Item -Path $sourcePath -Destination $exportPath -Force
                Write-Host "  [OK] Exported file: $item" -ForegroundColor Green
            }
        }
    }
    
    # Create manifest
    $manifest = @{
        timestamp = Get-Date -Format 'o'
        version = '1.0.1'
        projectPath = $projectPath
        items = $itemsToExport
    } | ConvertTo-Json
    
    $manifest | Out-File -FilePath "$exportPath\MANIFEST.json" -Force
    Write-Host "  [OK] Manifest created" -ForegroundColor Green
}

# Sync from cloud to project
function Sync-CloudToProject {
    Write-Host "`n[SYNC] Syncing from D: cloud to C: project..." -ForegroundColor Yellow
    
    $syncItems = @(
        @{ cloud = "$cloudPath\configs"; local = "$projectPath\.config"; type = 'folder' },
        @{ cloud = "$cloudPath\imports"; local = $projectPath; type = 'import' }
    )
    
    foreach ($item in $syncItems) {
        if (Test-Path $item.cloud) {
            Write-Host "  [SYNC] $($item.cloud)" -ForegroundColor Cyan
            Copy-Item -Path $item.cloud\* -Destination $item.local -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Synced: $($item.cloud)" -ForegroundColor Green
        }
    }
    
    Write-Host "`n[SUCCESS] Sync complete!" -ForegroundColor Green
}

# Backup project to cloud
function Backup-ToCloud {
    Write-Host "`n[BACKUP] Creating backup of C: project..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupName = "networkbuster_backup_$timestamp"
    $backupFile = "$backupPath\$backupName.zip"
    
    # Exclude node_modules and large files
    $excludePatterns = @('node_modules', '.git\objects', 'dist', 'build', '*.log')
    
    Write-Host "  [INFO] Compressing project..." -ForegroundColor Cyan
    
    try {
        # Create zip with exclusions
        $files = Get-ChildItem -Path $projectPath -Recurse -File | 
            Where-Object { 
                $exclude = $false
                foreach ($pattern in $excludePatterns) {
                    if ($_.FullName -like "*$pattern*") {
                        $exclude = $true
                        break
                    }
                }
                -not $exclude
            }
        
        Compress-Archive -Path $files.FullName -DestinationPath $backupFile -Force
        Write-Host "  [OK] Backup created: $backupFile" -ForegroundColor Green
        Write-Host "  [SIZE] $('{0:N2}' -f ((Get-Item $backupFile).Length / 1MB)) MB" -ForegroundColor Cyan
    } catch {
        Write-Host "  [ERROR] Backup failed: $_" -ForegroundColor Red
    }
    
    # Cleanup old backups (keep last 10)
    Write-Host "`n[CLEANUP] Removing old backups (keeping 10)..." -ForegroundColor Yellow
    
    $backups = Get-ChildItem -Path $backupPath -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -gt 10) {
        $toDelete = $backups | Select-Object -Skip 10
        foreach ($backup in $toDelete) {
            Remove-Item -Path $backup.FullName -Force
            Write-Host "  [OK] Deleted: $($backup.Name)" -ForegroundColor Green
        }
    }
}

# Restore from cloud backup
function Restore-FromCloud {
    Write-Host "`n[RESTORE] Listing available backups..." -ForegroundColor Yellow
    
    $backups = Get-ChildItem -Path $backupPath -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "  [ERROR] No backups found" -ForegroundColor Red
        return
    }
    
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $size = '{0:N2}' -f ($backups[$i].Length / 1MB)
        Write-Host "  [$i] $($backups[$i].Name) ($size MB)" -ForegroundColor Cyan
    }
    
    Write-Host "`nTo restore, run: restore-networkbuster.ps1 -BackupIndex <number>"
}

# Attach PFX certificate to cloud storage
function Attach-PfxToCloud {
    param(
        [string]$SourcePath,
        [string]$Password
    )

    Write-Host "`n[CERT] Attaching PFX certificate to D: cloud storage..." -ForegroundColor Yellow

    if (-not (Test-Path $certificatePath)) {
        New-Item -ItemType Directory -Path $certificatePath -Force | Out-Null
        Write-Host "  [OK] Created certificates folder: $certificatePath" -ForegroundColor Green
    }

    $destinationPath = Join-Path $certificatePath 'networkbustersetup.pfx'
    $passwordPath = [System.IO.Path]::ChangeExtension($destinationPath, '.password.txt')

    if (-not $PSBoundParameters.ContainsKey('SourcePath')) {
        if ((Test-Path $destinationPath) -and (Test-ControlledPfx -PfxPath $destinationPath)) {
            Write-Host "  [OK] Using existing controlled PFX: $destinationPath" -ForegroundColor Green
            return
        }

        if (Test-Path $destinationPath) {
            Write-Host "  [WARN] Existing PFX was not created by the controlled workflow; regenerating." -ForegroundColor Yellow
        }

        Write-Host "  [INFO] No source PFX supplied; creating a new controlled PFX." -ForegroundColor Cyan
        New-ControlledPfx -OutputPath $destinationPath -Password $Password
        Write-Host "  [OK] Controlled certificate ready at: $destinationPath" -ForegroundColor Green
        return
    }

    if (Test-Path $SourcePath) {
        Copy-Item -Path $SourcePath -Destination $destinationPath -Force

        $manifest = @{
            timestamp = Get-Date -Format 'o'
            source = $SourcePath
            destination = $destinationPath
            purpose = 'D: cloud certificate attachment'
        } | ConvertTo-Json

        $manifest | Out-File -FilePath (Join-Path $certificatePath 'networkbustersetup.manifest.json') -Force

        Write-Host "  [OK] Copied PFX to: $destinationPath" -ForegroundColor Green
        Write-Host "  [OK] Manifest written: $(Join-Path $certificatePath 'networkbustersetup.manifest.json')" -ForegroundColor Green
        return
    }

    Write-Host "  [WARN] Source PFX not found: $SourcePath" -ForegroundColor Yellow
    Write-Host "  [INFO] Creating a new controlled PFX in cloud storage instead." -ForegroundColor Cyan
    New-ControlledPfx -OutputPath $destinationPath -Password $Password
    Write-Host "  [OK] Controlled certificate ready at: $destinationPath" -ForegroundColor Green
}

# Show status
function Show-Status {
    Write-Host "`n[STATUS] Cloud Storage Configuration" -ForegroundColor Yellow
    
    Write-Host "`nProject Location:" -ForegroundColor Cyan
    Write-Host "  C: $projectPath" -ForegroundColor Green
    Write-Host "  Size: $('{0:N2}' -f ((Get-ChildItem $projectPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB)) MB"
    
    Write-Host "`nCloud Storage (D:):" -ForegroundColor Cyan
    Write-Host "  Root: $cloudPath"
    
    if (Test-Path $cloudPath) {
        Write-Host "  Status: MOUNTED" -ForegroundColor Green
        Write-Host "  Size: $('{0:N2}' -f ((Get-ChildItem $cloudPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB)) MB"
        
        Write-Host "`n  Subfolders:" -ForegroundColor Gray
        Get-ChildItem -Path $cloudPath -Directory | ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            Write-Host "    - $($_.Name): $('{0:N2}' -f ($size / 1MB)) MB"
        }
    } else {
        Write-Host "  Status: NOT ACCESSIBLE" -ForegroundColor Red
    }
    
    Write-Host "`nAvailable Backups:" -ForegroundColor Cyan
    $backups = @(Get-ChildItem -Path $backupPath -Filter "*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5)
    
    if ($backups.Count -gt 0) {
        foreach ($backup in $backups) {
            $size = '{0:N2}' -f ($backup.Length / 1MB)
            $date = $backup.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Write-Host "    $($backup.Name) - $size MB - $date" -ForegroundColor Green
        }
    } else {
        Write-Host "    No backups found" -ForegroundColor Gray
    }
}

# Main execution
switch ($Action) {
    'init' {
        Initialize-CloudStorage
    }
    'import' {
        Import-FromCloud
    }
    'export' {
        Export-ToCloud
    }
    'sync' {
        Sync-CloudToProject
    }
    'backup' {
        Backup-ToCloud
    }
    'restore' {
        Restore-FromCloud
    }
    'attach-pfx' {
        Attach-PfxToCloud
    }
    'create-pfx' {
        New-ControlledPfx
    }
    'status' {
        Show-Status
    }
    default {
        Show-Status
    }
}

Write-Host "`n[DONE] Cloud storage operation complete!`n" -ForegroundColor Green

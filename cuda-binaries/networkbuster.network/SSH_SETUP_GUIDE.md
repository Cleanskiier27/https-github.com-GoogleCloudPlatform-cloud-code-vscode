# SSH Setup & Configuration Guide for NetworkBuster

## Overview
This guide walks you through setting up SSH keys for secure GitHub authentication on Windows.

## Prerequisites
- Windows 10 or later
- Git for Windows (includes OpenSSH)
- PowerShell 5.1 or later

## Step 1: Set Up SSH Agent

### Option A: Automatic (Recommended)
Run the setup script:
```powershell
.\setup-ssh-agent.ps1
```

### Option B: Manual Setup
Start SSH Agent in PowerShell:
```powershell
Start-Service ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
```

## Step 2: Generate SSH Key

Run the PowerShell command:
```powershell
.\setup-ssh-agent.ps1
New-SSHKey -Email "your-email@example.com"
```

Or manually with ssh-keygen:
```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa -N ""
```

## Step 3: Copy Public Key to GitHub

Display your public key:
```powershell
.\setup-ssh-agent.ps1
Show-SSHPublicKey
```

Or manually:
```powershell
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub | Set-Clipboard
```

## Step 4: Add Key to GitHub

1. Go to https://github.com/settings/keys
2. Click "New SSH key"
3. Title: "Windows Development Machine"
4. Key type: Authentication Key
5. Paste your public key (copied above)
6. Click "Add SSH key"

## Step 5: Test SSH Connection

```powershell
ssh -T git@github.com
```

Expected output:
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

## Step 6: Configure Git to Use SSH

Set Git to use SSH for GitHub:
```powershell
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

Verify configuration:
```powershell
git config --global --list
```

## Step 7: Update Remote URL (If Needed)

Check current remote:
```powershell
git remote -v
```

If using HTTPS, change to SSH:
```powershell
git remote set-url origin git@github.com:NetworkBuster/networkbuster.net.git
```

Verify:
```powershell
git remote -v
```

## Troubleshooting

### SSH Agent Not Running
```powershell
Start-Service ssh-agent
```

### Permission Denied When Pushing
- Ensure SSH key is added to agent: `ssh-add $env:USERPROFILE\.ssh\id_rsa`
- Verify key is in GitHub SSH settings
- Test connection: `ssh -T git@github.com`

### "Could not open a connection to your authentication agent"
```powershell
Start-Service ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
```

### Generate New Key with Different Email
```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa_new -C "your-new-email@example.com"
ssh-add $env:USERPROFILE\.ssh\id_rsa_new
```

## Security Best Practices

1. **Never share your private key** (id_rsa file)
2. **Keep SSH key passphrase secure** (optional but recommended)
3. **Rotate keys periodically** (every 1-2 years)
4. **Use different keys per machine** (creates unique key per device)
5. **Enable 2FA on GitHub** for additional security
6. **Review authorized SSH keys regularly** at https://github.com/settings/keys

## Adding SSH Key to PowerShell Profile

To auto-load SSH agent at PowerShell startup:

1. Open PowerShell profile:
```powershell
notepad $PROFILE
```

2. Add this line:
```powershell
& "$PSScriptRoot\setup-ssh-agent.ps1"
```

3. Save and restart PowerShell

## File Locations

| Item | Path |
|------|------|
| SSH Config | `~/.ssh/config` |
| Private Key | `~/.ssh/id_rsa` |
| Public Key | `~/.ssh/id_rsa.pub` |
| Known Hosts | `~/.ssh/known_hosts` |

## Quick Reference Commands

```powershell
# Start SSH Agent
Start-Service ssh-agent

# Load SSH key
ssh-add $env:USERPROFILE\.ssh\id_rsa

# Show loaded keys
ssh-add -l

# Remove key from agent
ssh-add -d $env:USERPROFILE\.ssh\id_rsa

# Test GitHub connection
ssh -T git@github.com

# Generate new key
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa

# Copy public key to clipboard
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub | Set-Clipboard

# View public key
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

# Set Git to use SSH globally
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Update repository remote
git remote set-url origin git@github.com:NetworkBuster/networkbuster.net.git
```

## Additional Resources

- [GitHub SSH Key Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [OpenSSH Manual](https://man.openbsd.org/ssh-keygen)
- [Windows SSH Setup Guide](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_overview)

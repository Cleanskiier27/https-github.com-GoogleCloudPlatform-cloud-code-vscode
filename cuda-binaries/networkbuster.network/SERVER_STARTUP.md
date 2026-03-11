# NetworkBuster Server Startup Guide

## Summary
✅ **Server switched to port 3001** (from port 3000)  
✅ **Vite dev server configured for port 5173**  
✅ Both servers configured with automatic API proxy

---

## Quick Start (Choose One Method)

### Method 1: PowerShell (Recommended)
```powershell
# Open PowerShell and navigate to project root
cd "c:\Users\daypi\OneDrive\Documents\WindowsPowerShell\networkbuster.net"

# Run the startup script
.\Start-Server.ps1
```

Expected output:
```
🚀 NetworkBuster Development Server
🚀 Starting backend server on port 3001...
🚀 Server running at http://localhost:3001
```

### Method 2: Direct Node.js
```powershell
$env:PORT=3001
node server.js
```

### Method 3: npm Script
```powershell
npm start
```

---

## Access Points

### Backend Server (Port 3001)
- **Home Hub**: http://localhost:3001/home
- **AI World**: http://localhost:3001/ai-world
- **Control Panel**: http://localhost:3001/control-panel
- **Health Check**: http://localhost:3001/api/health
- **Status**: http://localhost:3001/api/status

### Frontend Dev Server (Port 5173)
```powershell
npm run dev
```
Access at: http://localhost:5173

---

## Stopping the Server
Press `Ctrl + C` in the terminal running the server.

---

## Troubleshooting

**If port 3001 is in use:**
```powershell
# Find what's using the port
Get-NetTCPConnection -LocalPort 3001 | Select-Object OwningProcess, State

# Kill the process (replace PID with actual process ID)
Stop-Process -Id <PID> -Force

# Or stop all Node processes
Stop-Process -Name node -Force
```

**Port not responding:**
1. Ensure you're in the correct directory:
   ```powershell
   Get-Location  # Should be: C:\Users\daypi\OneDrive\Documents\WindowsPowerShell\networkbuster.net
   ```

2. Check Node.js is working:
   ```powershell
   node --version   # Should show v24.12.0 or higher
   npm --version    # Should show 11.7.0 or higher
   ```

3. Test with the simple server:
   ```powershell
   $env:PORT=3001
   node test-server.js
   ```

---

## Configuration

### Backend Port
Set environment variable before starting:
```powershell
$env:PORT=3001  # or any available port
node server.js
```

### Vite Dev Server Port
Edit `vite.config.js`:
```javascript
server: {
  port: 5173,  // Change this
  // ...
}
```

### API Proxy Routes
All routes automatically proxy to the backend server:
- `/api/*` → `http://localhost:3001/api/*`
- `/home` → `http://localhost:3001/home`
- `/ai-world` → `http://localhost:3001/ai-world`
- `/control-panel` → `http://localhost:3001/control-panel`

---

## Files Modified
- `server.js` - Changed default port to 3001
- `vite.config.js` - Updated proxy targets to port 3001
- `Start-Server.ps1` - PowerShell startup script
- `start-server.js` - Node.js startup helper
- `test-server.js` - Simple test server for debugging

---

## Latest Commit
```
Commit: 3274e41
Message: Update server to port 3001 and add startup scripts
Branch: DATACENTRAL
```

---

## Next Steps
1. Start the backend: `.\Start-Server.ps1` or `node server.js`
2. In another terminal, start frontend: `npm run dev`
3. Access frontend at http://localhost:5173

Need help? Check server.js error logs or test with `node test-server.js`

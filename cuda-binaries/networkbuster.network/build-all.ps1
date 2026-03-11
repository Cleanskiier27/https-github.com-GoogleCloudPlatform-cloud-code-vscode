# Build all applications comprehensively
Write-Host "🚀 Building all NetworkBuster applications..." -ForegroundColor Cyan

# Build main React app (src/)
Write-Host "`n📦 Building main React app..." -ForegroundColor Yellow
if (Test-Path "src") {
    Write-Host "⚠️ Main app (src/) uses Vite - run 'npm run dev' for development"
}

# Build dashboard
Write-Host "`n📦 Building dashboard..." -ForegroundColor Yellow
if (Test-Path "dashboard") {
    Push-Location "dashboard"
    npm install
    npm run build
    Pop-Location
    Write-Host "✅ Dashboard built" -ForegroundColor Green
}

# Build overlay
Write-Host "`n📦 Building real-time overlay..." -ForegroundColor Yellow
if (Test-Path "challengerepo\real-time-overlay") {
    Push-Location "challengerepo\real-time-overlay"
    npm install
    npm run build
    Pop-Location
    Write-Host "✅ Overlay built" -ForegroundColor Green
}

Write-Host "`n✨ All applications built successfully!" -ForegroundColor Green
Write-Host "`n🚀 Ready to start server with: npm start" -ForegroundColor Cyan

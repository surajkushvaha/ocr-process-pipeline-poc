# Nginx Setup Script for Windows
# Run this as Administrator

Write-Host "Setting up Nginx for Flask multi-subdomain app..." -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# 1. Update hosts file
Write-Host "`n1. Updating hosts file..." -ForegroundColor Yellow
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile
$entries = @(
    "127.0.0.1 localhost",
    "127.0.0.1 api.localhost",
    "127.0.0.1 auth.localhost",
    "127.0.0.1 app.localhost"
)

foreach ($entry in $entries) {
    if ($hostsContent -notcontains $entry) {
        Add-Content -Path $hostsFile -Value $entry
        Write-Host "  Added: $entry" -ForegroundColor Green
    } else {
        Write-Host "  Already exists: $entry" -ForegroundColor Gray
    }
}

# 2. Check if Nginx is installed
Write-Host "`n2. Checking Nginx installation..." -ForegroundColor Yellow
$nginxPath = "C:\nginx"
if (-not (Test-Path $nginxPath)) {
    Write-Host "  Nginx not found at $nginxPath" -ForegroundColor Red
    Write-Host "  Please install Nginx first:" -ForegroundColor Yellow
    Write-Host "    - Download from: http://nginx.org/en/download.html" -ForegroundColor Cyan
    Write-Host "    - Extract to C:\nginx" -ForegroundColor Cyan
    Write-Host "    - Or install via Chocolatey: choco install nginx" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "  Nginx found at $nginxPath" -ForegroundColor Green
}

# 3. Copy nginx configuration
Write-Host "`n3. Copying Nginx configuration..." -ForegroundColor Yellow
$currentDir = Get-Location
$sourceConfig = Join-Path $currentDir "nginx.conf"
$destConfig = Join-Path $nginxPath "conf\nginx.conf"

if (Test-Path $sourceConfig) {
    # Backup existing config
    if (Test-Path $destConfig) {
        $backupConfig = "$destConfig.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $destConfig $backupConfig
        Write-Host "  Backed up existing config to: $backupConfig" -ForegroundColor Gray
    }
    
    # Copy new config
    Copy-Item $sourceConfig $destConfig -Force
    Write-Host "  Copied nginx.conf to $destConfig" -ForegroundColor Green
} else {
    Write-Host "  ERROR: nginx.conf not found in current directory!" -ForegroundColor Red
    exit 1
}

# 4. Test Nginx configuration
Write-Host "`n4. Testing Nginx configuration..." -ForegroundColor Yellow
$nginxExe = Join-Path $nginxPath "nginx.exe"
& $nginxExe -t
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Configuration test passed!" -ForegroundColor Green
} else {
    Write-Host "  Configuration test failed!" -ForegroundColor Red
    exit 1
}

# 5. Start/Restart Nginx
Write-Host "`n5. Starting Nginx..." -ForegroundColor Yellow
$nginxProcess = Get-Process -Name nginx -ErrorAction SilentlyContinue
if ($nginxProcess) {
    Write-Host "  Stopping existing Nginx process..." -ForegroundColor Gray
    & $nginxExe -s stop
    Start-Sleep -Seconds 2
}

Start-Process -FilePath $nginxExe -WorkingDirectory $nginxPath -WindowStyle Hidden
Write-Host "  Nginx started successfully!" -ForegroundColor Green

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "`nYour subdomains are now configured:" -ForegroundColor Cyan
Write-Host "  - http://localhost (landing page)" -ForegroundColor White
Write-Host "  - http://app.localhost (main app)" -ForegroundColor White
Write-Host "  - http://auth.localhost (auth app)" -ForegroundColor White
Write-Host "  - http://api.localhost (API endpoints)" -ForegroundColor White
Write-Host "`nMake sure your Flask app is running on port 5000!" -ForegroundColor Yellow
Write-Host "`nUseful commands:" -ForegroundColor Cyan
Write-Host "  - Stop Nginx: C:\nginx\nginx.exe -s stop" -ForegroundColor White
Write-Host "  - Reload config: C:\nginx\nginx.exe -s reload" -ForegroundColor White
Write-Host "  - Test config: C:\nginx\nginx.exe -t" -ForegroundColor White

# One-time Windows Server Setup Script
# Installs Docker Desktop on Windows
# Run this as Administrator in PowerShell

Write-Host "=== OCR Pipeline - Windows Server Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is already installed
Write-Host "1. Checking if Docker is installed..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "   Docker is already installed: $dockerVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "Setup complete! You can now deploy:" -ForegroundColor Cyan
        Write-Host "   .\deploy.ps1 -Target docker-compose -Environment dev" -ForegroundColor White
        exit 0
    }
} catch {
    Write-Host "   Docker not found. Proceeding with installation..." -ForegroundColor Gray
}

# Check if Chocolatey is installed
Write-Host ""
Write-Host "2. Checking for Chocolatey package manager..." -ForegroundColor Yellow
$chocoInstalled = $false
try {
    $chocoVersion = choco --version 2>$null
    if ($chocoVersion) {
        Write-Host "   Chocolatey is installed: v$chocoVersion" -ForegroundColor Green
        $chocoInstalled = $true
    }
} catch {
    Write-Host "   Chocolatey not found" -ForegroundColor Gray
}

if (-not $chocoInstalled) {
    Write-Host ""
    Write-Host "3. Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "   Chocolatey installed successfully" -ForegroundColor Green
}

# Install Docker Desktop
Write-Host ""
Write-Host "4. Installing Docker Desktop..." -ForegroundColor Yellow
Write-Host "   This may take several minutes..." -ForegroundColor Gray

choco install docker-desktop -y

if ($LASTEXITCODE -eq 0) {
    Write-Host "   Docker Desktop installed successfully" -ForegroundColor Green
} else {
    Write-Host "   Installation may have failed. Please check manually." -ForegroundColor Yellow
}

# Instructions
Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT Next Steps:" -ForegroundColor Yellow
Write-Host "1. Restart your computer" -ForegroundColor White
Write-Host "2. Launch Docker Desktop from Start Menu" -ForegroundColor White
Write-Host "3. Wait for Docker to start completely" -ForegroundColor White
Write-Host "4. Return to this directory and run:" -ForegroundColor White
Write-Host "   .\deploy.ps1 -Target docker-compose -Environment dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "If Docker Desktop is already running, you can deploy immediately!" -ForegroundColor Gray
Write-Host ""

# Alternative manual installation info
Write-Host ""
Write-Host "Alternative: Manual Installation" -ForegroundColor Yellow
Write-Host "If Chocolatey installation fails, download Docker Desktop manually:" -ForegroundColor Gray
Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
Write-Host ""

# Start Flask App Script
# This ensures Flask is configured to work with Nginx subdomains

Write-Host "Starting Flask app for multi-subdomain setup..." -ForegroundColor Green

$env:FLASK_APP = "backend.main"
$env:FLASK_ENV = "development"
$env:SERVER_NAME = "localhost:5000"

Write-Host "`nFlask will be accessible via:" -ForegroundColor Cyan
Write-Host "  - http://localhost (through Nginx)" -ForegroundColor White
Write-Host "  - http://app.localhost (through Nginx)" -ForegroundColor White
Write-Host "  - http://auth.localhost (through Nginx)" -ForegroundColor White
Write-Host "  - http://api.localhost (through Nginx)" -ForegroundColor White
Write-Host "`nStarting Flask on port 5000...`n" -ForegroundColor Yellow

# Start Flask
uv run python -m backend.main

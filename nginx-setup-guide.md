# Nginx Setup Guide

## Quick Start

1. **Install Nginx** (as Administrator):
   ```powershell
   choco install nginx
   ```

2. **Run setup script** (as Administrator):
   ```powershell
   .\setup-nginx.ps1
   ```

3. **Start Flask**:
   ```powershell
   .\start-flask.ps1
   ```

4. **Access your app**:
   - http://localhost (landing)
   - http://app.localhost (main app)
   - http://auth.localhost (auth app)
   - http://api.localhost (API)

## Useful Commands

```powershell
# Stop Nginx
C:\nginx\nginx.exe -s stop

# Reload config
C:\nginx\nginx.exe -s reload

# Test config
C:\nginx\nginx.exe -t
```

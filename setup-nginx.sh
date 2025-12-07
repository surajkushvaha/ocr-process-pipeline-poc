#!/bin/bash

# Nginx Setup Script for Linux
# Run this with sudo

echo "Setting up Nginx for Flask multi-subdomain app..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run with sudo!"
    exit 1
fi

# 1. Update hosts file
echo ""
echo "1. Updating hosts file..."
HOSTS_FILE="/etc/hosts"
ENTRIES=(
    "127.0.0.1 localhost"
    "127.0.0.1 api.localhost"
    "127.0.0.1 auth.localhost"
    "127.0.0.1 app.localhost"
)

for entry in "${ENTRIES[@]}"; do
    if grep -q "$entry" "$HOSTS_FILE"; then
        echo "  Already exists: $entry"
    else
        echo "$entry" >> "$HOSTS_FILE"
        echo "  Added: $entry"
    fi
done

# 2. Check if Nginx is installed
echo ""
echo "2. Checking Nginx installation..."
if ! command -v nginx &> /dev/null; then
    echo "  Nginx not found. Installing..."
    apt-get update
    apt-get install -y nginx
    echo "  Nginx installed"
else
    echo "  Nginx already installed"
fi

# 3. Copy nginx configuration
echo ""
echo "3. Copying Nginx configuration..."
CURRENT_DIR=$(pwd)
SOURCE_CONFIG="$CURRENT_DIR/nginx.conf"
DEST_CONFIG="/etc/nginx/nginx.conf"

if [ -f "$SOURCE_CONFIG" ]; then
    # Backup existing config
    if [ -f "$DEST_CONFIG" ]; then
        cp "$DEST_CONFIG" "$DEST_CONFIG.backup"
        echo "  Backed up existing config to $DEST_CONFIG.backup"
    fi
    
    cp "$SOURCE_CONFIG" "$DEST_CONFIG"
    echo "  Copied nginx.conf to $DEST_CONFIG"
else
    echo "  ERROR: nginx.conf not found in current directory!"
    exit 1
fi

# 4. Test nginx configuration
echo ""
echo "4. Testing Nginx configuration..."
if nginx -t; then
    echo "  Nginx configuration is valid"
else
    echo "  ERROR: Nginx configuration test failed!"
    echo "  Restoring backup..."
    if [ -f "$DEST_CONFIG.backup" ]; then
        mv "$DEST_CONFIG.backup" "$DEST_CONFIG"
    fi
    exit 1
fi

# 5. Restart nginx
echo ""
echo "5. Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

if systemctl is-active --quiet nginx; then
    echo "  Nginx is running"
else
    echo "  ERROR: Nginx failed to start!"
    exit 1
fi

# Success
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Nginx is configured for:"
echo "  http://localhost"
echo "  http://api.localhost"
echo "  http://auth.localhost"
echo "  http://app.localhost"
echo ""
echo "Make sure your Flask app is running on port 5000"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status nginx   - Check Nginx status"
echo "  sudo systemctl restart nginx  - Restart Nginx"
echo "  sudo nginx -t                 - Test configuration"
echo "  sudo tail -f /var/log/nginx/error.log - View error logs"
echo ""

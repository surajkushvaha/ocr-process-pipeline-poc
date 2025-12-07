#!/bin/bash

# One-time Linux Server Setup Script
# Installs Docker and Docker Compose

echo "=== OCR Pipeline - Server Setup ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "1. Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo ""
echo "2. Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
echo ""
echo "3. Installing Docker Compose..."
apt-get install docker-compose-plugin -y

# Start Docker
echo ""
echo "4. Starting Docker service..."
systemctl enable docker
systemctl start docker

# Add current user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    echo ""
    echo "5. Adding $SUDO_USER to docker group..."
    usermod -aG docker $SUDO_USER
fi

# Verify installation
echo ""
echo "6. Verifying installation..."
docker --version
docker compose version

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "✅ Docker installed"
echo "✅ Docker Compose installed"
echo ""
echo "⚠️  IMPORTANT: Log out and back in for Docker permissions to take effect"
echo ""
echo "Next steps:"
echo "  1. Clone your repository"
echo "  2. Run: ./deploy.sh docker-compose prod"
echo ""

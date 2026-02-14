#!/bin/bash
# Plex Quality Manager - Installation Script

set -e  # Exit on error

echo "=========================================="
echo "Plex Quality Manager - Installation"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: Do not run this script as root/sudo"
   echo "Run as normal user: ./install.sh"
   exit 1
fi

# Check OS
if ! command -v apt &> /dev/null; then
    echo "ERROR: This installer requires apt (Ubuntu/Debian)"
    echo "For other distros, install dependencies manually:"
    echo "  - iperf3"
    echo "  - jq"
    echo "  - bc"
    echo "  - curl"
    exit 1
fi

echo "Step 1: Installing dependencies..."
echo "This will require sudo password."
echo ""

# Install dependencies
sudo apt update
sudo apt install -y iperf3 jq bc curl

echo ""
echo "Dependencies installed successfully!"
echo ""

# Get Plex server details
echo "Step 2: Configuration"
echo ""

read -p "Enter your Plex server IP address (e.g., 192.168.1.100): " PLEX_IP
read -p "Enter your Plex authentication token: " PLEX_TOKEN
read -p "Enter your remote server WireGuard IP (e.g., 10.100.0.1): " LIGHTSAIL_IP

echo ""
echo "Configuration:"
echo "  Plex Server: http://$PLEX_IP:32400"
echo "  Remote Server: $LIGHTSAIL_IP"
echo ""

read -p "Is this correct? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Installation cancelled"
    exit 0
fi

echo ""
echo "Step 3: Installing script..."

# Create configured script
cat plex-quality-manager.sh | \
    sed "s|PLEX_SERVER=\".*\"|PLEX_SERVER=\"http://$PLEX_IP:32400\"|" | \
    sed "s|PLEX_TOKEN=\".*\"|PLEX_TOKEN=\"$PLEX_TOKEN\"|" | \
    sed "s|LIGHTSAIL_IP=\".*\"|LIGHTSAIL_IP=\"$LIGHTSAIL_IP\"|" | \
    sudo tee /usr/local/bin/plex-quality-manager.sh > /dev/null

# Make executable
sudo chmod +x /usr/local/bin/plex-quality-manager.sh

# Create log file
sudo touch /var/log/plex-quality-manager.log
sudo chown $USER:$USER /var/log/plex-quality-manager.log

echo "Script installed to: /usr/local/bin/plex-quality-manager.sh"
echo ""

echo "Step 4: Testing..."
echo ""

# Test the script
if /usr/local/bin/plex-quality-manager.sh; then
    echo ""
    echo "✓ Test successful!"
    echo ""
else
    echo ""
    echo "✗ Test failed. Please check:"
    echo "  - Plex server is running and accessible"
    echo "  - Plex token is correct"
    echo "  - WireGuard tunnel is active"
    echo "  - iperf3 server is running on remote server"
    echo ""
    echo "Run manually to debug:"
    echo "  /usr/local/bin/plex-quality-manager.sh"
    exit 1
fi

echo "Step 5: Setting up automatic execution..."
echo ""

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "plex-quality-manager"; then
    echo "Cron job already exists, skipping..."
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/plex-quality-manager.sh") | crontab -
    echo "✓ Cron job added (runs every 15 minutes)"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "The script will now run automatically every 15 minutes."
echo ""
echo "Useful commands:"
echo "  View logs:     tail -f /var/log/plex-quality-manager.log"
echo "  Run manually:  /usr/local/bin/plex-quality-manager.sh"
echo "  Edit cron:     crontab -e"
echo ""
echo "Next steps:"
echo "  1. Verify iperf3 is running on remote server:"
echo "     iperf3 -c $LIGHTSAIL_IP -t 5"
echo ""
echo "  2. Monitor the log file to see quality adjustments:"
echo "     tail -f /var/log/plex-quality-manager.log"
echo ""

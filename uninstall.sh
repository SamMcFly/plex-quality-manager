#!/bin/bash
# Plex Quality Manager - Uninstall Script

echo "=========================================="
echo "Plex Quality Manager - Uninstall"
echo "=========================================="
echo ""

read -p "This will remove Plex Quality Manager. Continue? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Uninstall cancelled"
    exit 0
fi

echo ""
echo "Removing cron job..."
crontab -l 2>/dev/null | grep -v "plex-quality-manager" | crontab - 2>/dev/null || true
echo "✓ Cron job removed"

echo ""
echo "Removing script..."
sudo rm -f /usr/local/bin/plex-quality-manager.sh
echo "✓ Script removed"

echo ""
read -p "Remove log file? (y/n): " remove_log
if [[ $remove_log == "y" || $remove_log == "Y" ]]; then
    sudo rm -f /var/log/plex-quality-manager.log
    echo "✓ Log file removed"
else
    echo "Log file kept at: /var/log/plex-quality-manager.log"
fi

echo ""
read -p "Remove dependencies (iperf3, jq, bc)? (y/n): " remove_deps
if [[ $remove_deps == "y" || $remove_deps == "Y" ]]; then
    sudo apt remove -y iperf3 jq bc
    sudo apt autoremove -y
    echo "✓ Dependencies removed"
else
    echo "Dependencies kept (may be used by other software)"
fi

echo ""
echo "=========================================="
echo "Uninstall Complete!"
echo "=========================================="
echo ""

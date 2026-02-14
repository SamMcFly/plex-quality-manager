# Remote Server Setup (AWS Lightsail, VPS, etc.)

This document covers setting up the remote server component for Plex Quality Manager.

## Requirements

- Ubuntu/Debian-based Linux server
- Root or sudo access
- WireGuard VPN already configured and running

## Installation

### 1. Install iperf3

```bash
sudo apt update
sudo apt install -y iperf3
```

### 2. Install iperf3 as a Service

Copy the service file:

```bash
sudo cp iperf3.service /etc/systemd/system/iperf3.service
```

Or create it manually:

```bash
sudo nano /etc/systemd/system/iperf3.service
```

Paste the following content:

```ini
[Unit]
Description=iperf3 server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/iperf3 -s
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Save and exit (Ctrl+X, Y, Enter).

### 3. Enable and Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable iperf3 to start on boot
sudo systemctl enable iperf3

# Start iperf3 now
sudo systemctl start iperf3

# Verify it's running
sudo systemctl status iperf3
```

You should see:
```
● iperf3.service - iperf3 server
     Loaded: loaded (/etc/systemd/system/iperf3.service; enabled)
     Active: active (running) since...
```

### 4. Verify iperf3 is Listening

```bash
# Check if iperf3 is listening on port 5201
sudo netstat -tulpn | grep 5201
```

You should see:
```
tcp        0      0 0.0.0.0:5201            0.0.0.0:*               LISTEN      12345/iperf3
```

### 5. Test from Local Network

From your local server (where the Plex Quality Manager script will run):

```bash
# Replace 10.100.0.1 with your remote server's WireGuard IP
iperf3 -c 10.100.0.1 -t 5
```

You should see upload speed test results.

## Firewall Configuration

If you have a firewall (ufw, iptables, etc.), you may need to allow iperf3:

### UFW (Ubuntu Firewall)

```bash
# Allow iperf3 port (only needed if accessing from outside the VPN)
sudo ufw allow 5201/tcp
sudo ufw reload
```

**Note:** If you're only accessing iperf3 through the WireGuard tunnel, you don't need to open this port on the public firewall.

## Troubleshooting

### Service Won't Start

Check logs:
```bash
sudo journalctl -u iperf3 -n 50
```

Common issues:
- iperf3 not installed: `sudo apt install iperf3`
- Port already in use: `sudo netstat -tulpn | grep 5201`

### Can't Connect from Local Network

Verify:
1. WireGuard tunnel is active: `sudo wg show`
2. Can ping remote server: `ping 10.100.0.1`
3. iperf3 is running: `sudo systemctl status iperf3`
4. Port is listening: `sudo netstat -tulpn | grep 5201`

### Service Crashes or Stops

The service is configured to auto-restart (`Restart=always`), but if it keeps crashing:

```bash
# Check logs
sudo journalctl -u iperf3 -f

# Restart manually
sudo systemctl restart iperf3
```

## Security Considerations

- iperf3 has no authentication - ensure it's only accessible via the WireGuard tunnel
- Don't expose port 5201 to the public internet unless necessary
- Consider using WireGuard's allowed IPs to restrict access further

## Maintenance

### View Logs

```bash
# View recent logs
sudo journalctl -u iperf3 -n 100

# Follow logs in real-time
sudo journalctl -u iperf3 -f
```

### Restart Service

```bash
sudo systemctl restart iperf3
```

### Stop Service

```bash
sudo systemctl stop iperf3
```

### Disable Service (stop auto-start on boot)

```bash
sudo systemctl disable iperf3
```

## Performance Impact

iperf3 server is very lightweight:
- **RAM:** ~5MB when idle
- **CPU:** Minimal (only during tests)
- **Network:** Only uses bandwidth during active tests

## Uninstall

To remove iperf3 service:

```bash
# Stop and disable
sudo systemctl stop iperf3
sudo systemctl disable iperf3

# Remove service file
sudo rm /etc/systemd/system/iperf3.service

# Reload systemd
sudo systemctl daemon-reload

# Optional: Remove iperf3 package
sudo apt remove iperf3
```

## Complete!

Your remote server is now ready to accept iperf3 bandwidth tests from your local Plex Quality Manager script.

Return to the main README.md to continue with local server setup.

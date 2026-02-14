# Quick Start - Bash Version

Get up and running with the Bash version in 15 minutes.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] **WireGuard tunnel working** from home to remote server
- [ ] Can ping remote tunnel IP (e.g., `ping 10.100.0.1`)
- [ ] Ubuntu/Debian VM or server on home network (1GB RAM minimum)
- [ ] Plex server running on home network
- [ ] Plex authentication token
- [ ] Remote VPS/Lightsail server with root access

**Don't have WireGuard?** See [WireGuard Setup Guide](WireGuard-Setup) first.

## Step-by-Step Installation

### 1. Set Up Remote Server (5 minutes)

On your VPS (AWS Lightsail, DigitalOcean, etc.):

```bash
# Install iperf3
sudo apt update && sudo apt install -y iperf3

# Download service file
sudo curl -o /etc/systemd/system/iperf3.service \
  https://raw.githubusercontent.com/YOUR_USERNAME/plex-quality-manager/main/iperf3.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable iperf3
sudo systemctl start iperf3

# Verify
sudo systemctl status iperf3
```

### 2. Install on Home Server (5 minutes)

On your Ubuntu VM (the one with WireGuard):

```bash
# Clone repo
git clone https://github.com/YOUR_USERNAME/plex-quality-manager.git
cd plex-quality-manager

# Run installer
chmod +x install.sh
./install.sh
```

The installer will ask for:
- Plex server IP (e.g., `192.168.2.215`)
- Plex token (see below)
- Remote server IP (e.g., `10.100.0.1`)

### 3. Get Your Plex Token

1. Open Plex Web: `http://your-plex-ip:32400/web`
2. Play any media
3. Click `...` → `Get Info` → `View XML`
4. Look for `X-Plex-Token=...` in URL
5. Copy the token value

### 4. Test It

```bash
# Run manually
/usr/local/bin/plex-quality-manager.sh

# Should see:
# [INFO] Testing upload speed...
# [INFO] Upload: 24.5 Mbps
# [INFO] Recommended: 12 Mbps 1080p
# [SUCCESS] Updated to 12 Mbps 1080p
```

### 5. Done!

The script is now running every 15 minutes automatically.

**View logs:**
```bash
tail -f /var/log/plex-quality-manager.log
```

## Verification

### Check WireGuard Tunnel
```bash
# On your home VM
sudo wg show
# Should show active tunnel with recent handshake

ping 10.100.0.1
# Should get replies
```

### Check iperf3 Server
```bash
# Test from home VM
iperf3 -c 10.100.0.1 -t 5
# Should show upload speed results
```

### Check Plex API
```bash
# Test Plex connection (replace IP and token)
curl -s "http://192.168.2.215:32400/?X-Plex-Token=YOUR_TOKEN"
# Should return XML data
```

### Check Cron Job
```bash
crontab -l | grep plex
# Should show: */15 * * * * /usr/local/bin/plex-quality-manager.sh
```

## What Happens Now

Every 15 minutes:
1. Script checks if anyone is streaming
2. If idle and `SKIP_TEST_WHEN_IDLE=true`: skips test
3. If active: runs 10-second upload test through tunnel
4. Calculates optimal quality based on available bandwidth
5. Updates Plex if quality needs adjustment
6. Logs everything

## Monitoring

### Watch Real-Time
```bash
tail -f /var/log/plex-quality-manager.log
```

### View Recent Changes
```bash
grep "Recommended" /var/log/plex-quality-manager.log | tail -20
```

### View Upload History
```bash
grep "Upload:" /var/log/plex-quality-manager.log | tail -20
```

## Customization

Edit the script to customize:

```bash
sudo nano /usr/local/bin/plex-quality-manager.sh
```

Common changes:
- Peak hours: Change `PEAK_HOURS_START` and `PEAK_HOURS_END`
- Safety margins: Adjust percentages
- Skip when idle: Toggle `SKIP_TEST_WHEN_IDLE`

See [Configuration Guide](Configuration) for details.

## Troubleshooting

### Script Not Running
```bash
# Check cron
sudo systemctl status cron

# Check cron logs
grep CRON /var/log/syslog | tail -20
```

### Can't Connect to Plex
```bash
# Test manually
curl -s "http://YOUR_PLEX_IP:32400/?X-Plex-Token=YOUR_TOKEN"

# Check Plex is running
sudo systemctl status plexmediaserver
```

### iperf3 Test Fails
```bash
# Verify tunnel
sudo wg show
ping 10.100.0.1

# Test iperf3 manually
iperf3 -c 10.100.0.1 -t 5
```

See [Troubleshooting Guide](Troubleshooting) for more solutions.

## Next Steps

- [Configuration Options](Configuration) - Customize thresholds
- [Understanding Logs](Log-Examples) - Interpret the output
- [Performance Tuning](Performance-Tuning) - Optimize for your setup

## Quick Reference

**Important Files:**
- Script: `/usr/local/bin/plex-quality-manager.sh`
- Logs: `/var/log/plex-quality-manager.log`
- Cron: `crontab -e`

**Important Commands:**
```bash
# Run manually
/usr/local/bin/plex-quality-manager.sh

# View logs
tail -f /var/log/plex-quality-manager.log

# Edit cron
crontab -e

# Edit script
sudo nano /usr/local/bin/plex-quality-manager.sh
```

**Getting Help:**
- [Troubleshooting](Troubleshooting)
- [GitHub Issues](https://github.com/YOUR_USERNAME/plex-quality-manager/issues)

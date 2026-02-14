# Plex Quality Manager - Python Version

## Overview

This Python version runs directly on your Plex server and tests your actual WAN upload speed (no VPN tunnel or remote server required). It's simpler to set up but may be less accurate if your ISP throttles speedtest servers.

## When to Use This Version

**Use Python version if:**
- ✅ You run Plex directly on a machine with Python support
- ✅ You don't have a VPN tunnel to a remote server
- ✅ You want a simpler setup without iperf3/VPS requirements
- ✅ Your ISP doesn't throttle speedtest.net

**Use Bash version (main) if:**
- ✅ You have Plex behind nginx reverse proxy with VPN tunnel
- ✅ You want to test actual tunnel bandwidth (more accurate)
- ✅ You have a remote VPS/Lightsail server
- ✅ Your ISP throttles speedtest servers

## Requirements

- Python 3.6 or higher
- Plex Media Server running on the same machine
- Internet connection for speed testing

## Installation

### 1. Install Python Dependencies

```bash
# On your Plex server
pip3 install speedtest-cli requests

# Or if you prefer:
python3 -m pip install speedtest-cli requests
```

### 2. Download the Script

```bash
# Download from GitHub or copy the script
sudo curl -o /usr/local/bin/plex-quality-manager.py \
    https://raw.githubusercontent.com/YOUR_USERNAME/plex-quality-manager/main/plex-quality-manager.py

# Make executable
sudo chmod +x /usr/local/bin/plex-quality-manager.py
```

### 3. Configure

Edit the script:

```bash
sudo nano /usr/local/bin/plex-quality-manager.py
```

Update these values:
```python
PLEX_URL = "http://localhost:32400"  # Use localhost if on Plex server
PLEX_TOKEN = "YOUR_PLEX_TOKEN_HERE"  # Your Plex token
```

**Getting Your Plex Token:**
Same as bash version - see main README.md

### 4. Test

Run manually:

```bash
python3 /usr/local/bin/plex-quality-manager.py
```

You should see:
```
[2026-02-14 12:00:00] [INFO] ==================================================
[2026-02-14 12:00:00] [INFO] Plex Quality Manager (Python Version)
[2026-02-14 12:00:00] [INFO] ==================================================
[2026-02-14 12:00:00] [INFO] Current quality: 12 Mbps 1080p
[2026-02-14 12:00:00] [INFO] Checking for active streams...
[2026-02-14 12:00:00] [INFO] No active streams
[2026-02-14 12:00:00] [INFO] Off-peak - using 65% safety margin
[2026-02-14 12:00:00] [INFO] Testing upload speed (this may take 30-60 seconds)...
[2026-02-14 12:00:45] [INFO] Upload speed: 28.45 Mbps
[2026-02-14 12:00:45] [INFO] Upload: 28.45 Mbps | Usable (65%): 18.49 Mbps | Available: 18.49 Mbps
[2026-02-14 12:00:45] [INFO] Recommended: 12 Mbps 1080p
[2026-02-14 12:00:45] [INFO] Quality already optimal
[2026-02-14 12:00:45] [INFO] ==================================================
```

### 5. Set Up Cron Job

**Linux/macOS:**

```bash
crontab -e
```

Add (runs every 30 minutes - slower than bash version because speedtest takes longer):
```
*/30 * * * * /usr/bin/python3 /usr/local/bin/plex-quality-manager.py
```

**Windows (Task Scheduler):**

1. Open Task Scheduler
2. Create Basic Task
   - Name: "Plex Quality Manager"
   - Trigger: Daily, repeat every 30 minutes
   - Action: Start a Program
     - Program: `python.exe`
     - Arguments: `C:\Scripts\plex-quality-manager.py`

## Configuration Options

Edit these in the script:

```python
# Skip test when no one is streaming
SKIP_TEST_WHEN_IDLE = True

# Peak hours (5 PM - 11 PM)
PEAK_HOURS_START = 17
PEAK_HOURS_END = 23

# Safety margins
PEAK_SAFETY_MARGIN = 0.50    # 50% during peak
OFFPEAK_SAFETY_MARGIN = 0.65  # 65% off-peak

# Quality thresholds (same as bash version)
QUALITY_MAP = [
    (25, 20000, "20 Mbps 1080p"),
    (18, 12000, "12 Mbps 1080p"),
    # ... etc
]
```

## Differences from Bash Version

| Feature | Python Version | Bash Version |
|---------|---------------|--------------|
| Speed Test | speedtest-cli (30-60s) | iperf3 through tunnel (10s) |
| Accuracy | Good (if ISP doesn't throttle) | Excellent (actual tunnel) |
| Dependencies | Python + 2 packages | iperf3, jq, bc, curl |
| Setup Complexity | Simple (one file) | Moderate (needs VPS) |
| Test Duration | 30-60 seconds | 10 seconds |
| Recommended Run | Every 30 min | Every 15 min |
| Best For | Simple setups | VPN tunnel setups |

## Troubleshooting

### Speedtest is Slow

This is normal - speedtest-cli takes 30-60 seconds per test. The bash version is faster because it uses iperf3 (10 seconds).

**Solution:** Run less frequently (every 30-60 minutes instead of 15).

### Speedtest Fails

```
ERROR: Speedtest failed: ...
```

**Causes:**
- No internet connection
- Firewall blocking speedtest
- speedtest-cli not installed

**Fix:**
```bash
# Test speedtest manually
speedtest-cli --simple

# Reinstall if needed
pip3 install --upgrade speedtest-cli
```

### Different Results than Actual Upload

Speedtest may show different results than your actual upload because:
- ISP may prioritize/throttle speedtest servers
- Speedtest uses different servers than your Plex traffic
- Time of day affects results

**Solution:** Use the bash version with iperf3 for more accurate results.

### Permission Errors on Windows

Run as Administrator or adjust file permissions.

### Python Not Found

**Linux:**
```bash
# Install Python 3
sudo apt install python3 python3-pip
```

**Windows:**
Download from https://www.python.org/downloads/

## View Logs

```bash
# Linux/macOS
tail -f /var/log/plex-quality-manager-python.log

# Windows
type C:\Logs\plex-quality-manager-python.log
```

## Uninstall

```bash
# Remove script
sudo rm /usr/local/bin/plex-quality-manager.py

# Remove log
sudo rm /var/log/plex-quality-manager-python.log

# Remove cron job
crontab -e
# Delete the line for plex-quality-manager.py

# Uninstall Python packages (optional)
pip3 uninstall speedtest-cli requests
```

## Performance Notes

- **Speed test duration:** 30-60 seconds per run
- **Memory:** ~50-100MB during test
- **CPU:** Moderate during speed test, minimal otherwise
- **Network:** Uses ~50-200MB per test

Run less frequently than the bash version (every 30-60 min instead of 15 min) due to longer test duration.

## Advanced: Custom Speed Test

If you prefer a different speed test method, modify the `test_upload_speed()` function:

```python
def test_upload_speed():
    """Custom upload test using your preferred method"""
    # Example: Use fast.com API, Netflix's speed test
    # Or call external command
    import subprocess
    result = subprocess.run(['speedtest', '--upload-only'], 
                          capture_output=True, text=True)
    # Parse result and return Mbps
    return upload_mbps
```

## Why Two Versions?

**Bash version** is designed for the specific use case of Plex behind nginx reverse proxy with VPN tunnel - it tests the actual tunnel bandwidth which is the real bottleneck.

**Python version** is a simpler alternative for users who:
- Run Plex directly exposed to internet
- Don't have VPN tunnel setup
- Want easier installation
- Don't mind slower/less frequent testing

Both versions use the same quality adjustment logic - just different methods of measuring upload speed.

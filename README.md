# Plex Quality Manager

Automatically adjusts Plex remote streaming quality based on real-time upload bandwidth availability.

## 🚀 Quick Start - Choose Your Version

This tool comes in **two versions** depending on your setup:

### 📊 Version Comparison

| | **Bash Version** (Recommended) | **Python Version** (Simple) |
|---|---|---|
| **Best For** | Plex behind VPN tunnel + reverse proxy | Direct Plex setup, no VPN |
| **Speed Test** | iperf3 through tunnel (10 sec) | speedtest-cli (30-60 sec) |
| **Accuracy** | Excellent (actual tunnel bandwidth) | Good (if ISP doesn't throttle) |
| **Setup** | Moderate (needs VPS + WireGuard) | Simple (one Python script) |
| **Requirements** | VPS, WireGuard, Ubuntu VM | Python 3, Plex server |
| **Test Frequency** | Every 15 minutes | Every 30 minutes |
| **Platform** | Linux only | Cross-platform |

### 🎯 Which Version Should I Use?

**→ Use BASH version if:**
- ✅ You have Plex behind nginx reverse proxy on a VPS
- ✅ You use WireGuard/OpenVPN tunnel from home to VPS
- ✅ You have AWS Lightsail, DigitalOcean, or similar VPS
- ✅ You want accurate tunnel bandwidth measurement
- ✅ You have cable/DSL with variable upload

**→ Use PYTHON version if:**
- ✅ Your Plex server is directly exposed to internet (no VPN)
- ✅ You want simple setup without VPS requirements
- ✅ You can run Python on your Plex server
- ✅ Your ISP doesn't throttle speedtest.net
- ✅ You're okay with slower/less frequent testing

**Installation Links:**
- **Bash Version:** [Continue reading below](#background) ← The main version documented here
- **Python Version:** See [PYTHON_VERSION.md](PYTHON_VERSION.md) for installation

---

## Background

This project was created to solve a specific problem: **streaming Plex remotely through an nginx reverse proxy on a VPS while dealing with variable cable ISP upload speeds**.

### The Problem

Many home users run Plex behind an nginx reverse proxy on a VPS/cloud server (AWS Lightsail, DigitalOcean, etc.) to:
- Avoid ISP blocking of common media server ports
- Get a clean external URL (plex.yourdomain.com instead of home-ip:32400)
- Bypass carrier-grade NAT or dynamic IP issues
- Use SSL certificates easily

However, this setup creates a unique challenge: **your Plex streams are limited by your home upload speed, which varies significantly on cable ISP connections due to neighborhood congestion**.

### The Specific Scenario This Solves

**Traditional Plex Setup:**
```
Remote User → Internet → Home Plex Server (static quality setting)
```
Problem: Easy to set quality, but limited by ISP port restrictions.

**Plex Behind VPS Setup:**
```
Remote User → Internet → VPS (nginx) → VPN Tunnel → Home Plex Server
```
Problem: Quality is limited by home upload AND it varies by time of day!

**With Cable ISP:**
- **3 AM:** 28-30 Mbps upload available (node empty)
- **8 PM:** 12-15 Mbps upload available (neighborhood congestion)
- **Static quality settings fail:** Set too high = buffering at peak. Set too low = wasted bandwidth off-peak.

### The Solution

This script continuously monitors your **actual usable upload bandwidth through the VPN tunnel** and dynamically adjusts Plex's quality limit to match current network conditions.

**Result:** Maximum quality during off-peak hours, automatic reduction during congestion to prevent buffering.

## Who Is This For?

This solution is ideal if you have:

✅ **Plex Media Server** running on your home network  
✅ **VPS/Cloud server** (AWS Lightsail, DigitalOcean, etc.) running nginx as reverse proxy  
✅ **VPN tunnel** (WireGuard, OpenVPN, etc.) from home to VPS  
✅ **Cable or DSL ISP** with variable/congested upload speeds  
✅ **Linux server or VM** on home network (can be small - 1GB RAM is fine)

### Example Setups That Benefit

**Setup 1: ISP Port Restrictions**
- Cable ISP blocks common ports
- Run WireGuard from home to AWS Lightsail
- nginx on Lightsail proxies to home Plex
- Upload varies 10-30 Mbps depending on time of day

**Setup 2: Carrier-Grade NAT**
- ISP uses CGNAT, can't port forward
- VPS with public IP runs nginx reverse proxy
- OpenVPN tunnel from home to VPS
- DSL upload varies 5-15 Mbps

**Setup 3: Clean External URL**
- Want plex.mydomain.com instead of IP:port
- nginx on cloud server handles SSL and domain
- WireGuard tunnel for security
- Cable upload congestion during peak hours

### Not For You If...

❌ You have **fiber with symmetric gigabit** (your upload is always stable)  
❌ You **don't use a VPN tunnel** to a remote proxy  
❌ You have **dedicated server hosting** (not home internet)  
❌ Your ISP has **stable upload** (business-class, some fiber)

## 📚 Documentation

- **Main README (you are here):** Bash version for VPN tunnel setups
- **[Python Version Guide](PYTHON_VERSION.md):** Simple version for direct Plex setups
- **[Remote Server Setup](REMOTE_SETUP.md):** Setting up iperf3 on VPS (bash version only)
- **[GitHub Wiki](../../wiki):** Detailed guides, troubleshooting, and examples

---

The remainder of this README covers the **Bash version** (VPN tunnel setup).

For the Python version, see [PYTHON_VERSION.md](PYTHON_VERSION.md).

---

## Overview

This script monitors your upload speed through a WireGuard VPN tunnel and dynamically adjusts Plex's "Limit remote stream bitrate" setting to prevent buffering while maximizing quality.

**Key Features:**
- ⚡ **Real-time bandwidth monitoring** - Tests upload speed every 15 minutes
- 🎯 **Smart quality adjustment** - Automatically sets optimal bitrate based on available bandwidth
- 📊 **Session-aware** - Accounts for current streaming usage when calculating available bandwidth
- 🕐 **Time-based optimization** - More conservative during peak hours (5-11 PM)
- 🔍 **Congestion detection** - Applies penalty when high packet retransmissions detected
- 📝 **Detailed logging** - Track all quality changes and bandwidth tests
- 💤 **Idle optimization** - Skips tests when no one is streaming (saves bandwidth)

## Use Case

This is designed for users who:
- Stream Plex remotely through a VPN tunnel (WireGuard, etc.)
- Have cable ISP with variable upload speeds
- Experience buffering during peak hours due to neighborhood congestion
- Want automatic quality adjustment without manual intervention

## Architecture

This solution sits between your home network and remote users, monitoring the VPN tunnel bandwidth that's actually available for Plex streaming.

```
Internet Users                  Cloud VPS (Public IP)              Home Network (Behind ISP)
─────────────                  ───────────────────────            ─────────────────────────

Remote Plex                         nginx                         
Client          ────────►      Reverse Proxy      ◄────VPN────►  Plex Server
(anywhere)                     (SSL/Domain)         Tunnel       192.168.x.x
                                                   WireGuard/     
                                                   OpenVPN        Quality Manager
                                   iperf3                         (monitors tunnel)
                                   server         ◄────test──    192.168.x.x
                                  (bandwidth                      
                                   testing)                       Tests upload every
                                                                  15 min, adjusts
                                                                  Plex quality
```

**Traffic Flow:**
1. Remote user connects to `plex.yourdomain.com` (your VPS)
2. nginx reverse proxy forwards to Plex via VPN tunnel
3. Plex streams through tunnel (limited by home upload)
4. Quality Manager monitors tunnel bandwidth
5. Adjusts Plex quality based on current upload capacity

**Why Monitor the Tunnel?**
- Your home upload to the VPS is the bottleneck
- Cable ISP upload varies based on neighborhood usage
- VPN adds ~5-10% overhead
- Real tunnel speed ≠ advertised ISP speed

## Requirements

### Hardware/Network
- Plex Media Server running on local network
- **Ubuntu/Debian server on local network** with WireGuard client configured
  - Can be VM with 1GB RAM (very lightweight)
  - **MUST be the same machine that has the WireGuard tunnel configured**
  - This is typically NOT your Plex server itself
- WireGuard VPN tunnel from local network to remote server (outbound connection)
- Remote server (AWS Lightsail, VPS, etc.) with iperf3 running

### Why the Script Must Run on the WireGuard Machine

**Critical:** The script MUST run on the machine that has the WireGuard tunnel configured, not just any machine on your network.

**Why?**
- The script tests upload speed **through the tunnel** (e.g., to 10.100.0.1)
- Only the machine with WireGuard configured can reach the tunnel IP
- Other machines on your LAN can't access the WireGuard network

**Example Setup:**
```
Home Network:
  - Plex Server: 192.168.2.215 (no WireGuard)
  - WireGuard VM: 192.168.2.222 (HAS WireGuard tunnel) ← Install script HERE
  - Gaming PC: 192.168.2.100 (no WireGuard)
  - Router: 192.168.2.1 (no WireGuard)

WireGuard Tunnel Network:
  - Local endpoint: 10.100.0.2 (WireGuard VM's tunnel IP)
  - Remote endpoint: 10.100.0.1 (Lightsail tunnel IP)

The script runs on 192.168.2.222 because only IT can ping 10.100.0.1
```

**Common Mistake:**
- ❌ Installing on Plex server that doesn't have WireGuard
- ❌ Installing on router (unless router runs WireGuard client)
- ✅ Installing on dedicated VM/server that runs WireGuard client

### Software Dependencies
- `iperf3` - Bandwidth testing
- `jq` - JSON parsing
- `awk` - Math calculations
- `curl` - Plex API calls
- `grep` - Text parsing

## Installation

### Prerequisites - WireGuard Tunnel Must Be Working

**Before installing this script, you need:**

1. **WireGuard installed and configured** on your local server/VM
2. **Active tunnel** to your remote server (VPS/Lightsail)
3. **Can ping the remote tunnel IP** from your local server

**Verify your WireGuard setup:**

```bash
# Check WireGuard is running
sudo wg show

# You should see something like:
# interface: wg0
#   public key: ...
#   private key: (hidden)
#   listening port: 51820
#
# peer: ...
#   endpoint: YOUR_VPS_IP:51820
#   allowed ips: 10.100.0.1/32
#   latest handshake: 30 seconds ago

# Test connectivity through tunnel
ping 10.100.0.1

# Should get replies - if not, fix WireGuard first!
```

**If WireGuard isn't working:**
- This script won't work - it needs to test through the tunnel
- Set up WireGuard first (see WireGuard documentation)
- Ensure your local server has the WireGuard **client** configured
- Ensure your remote VPS has the WireGuard **server** configured

**Typical WireGuard Tunnel IPs:**
- Local machine (where script runs): `10.100.0.2` or similar
- Remote VPS (Lightsail): `10.100.0.1` or similar
- These IPs are **separate** from your LAN IPs (192.168.x.x)

### 1. Set Up Remote Server (AWS Lightsail, VPS, etc.)

Install and configure iperf3 as a service:

```bash
# Install iperf3
sudo apt update
sudo apt install -y iperf3

# Copy the systemd service file
sudo cp iperf3.service /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable iperf3
sudo systemctl start iperf3

# Verify it's running
sudo systemctl status iperf3
```

### 2. Set Up Local Server (Ubuntu/Debian)

Install dependencies:

```bash
sudo apt update
sudo apt install -y iperf3 jq bc curl
```

Install the script:

```bash
# Copy script to system location
sudo cp plex-quality-manager.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/plex-quality-manager.sh

# Create log file
sudo touch /var/log/plex-quality-manager.log
sudo chown $USER:$USER /var/log/plex-quality-manager.log
```

### 3. Configure

Edit the script configuration:

```bash
sudo nano /usr/local/bin/plex-quality-manager.sh
```

Update these values at the top:
```bash
PLEX_SERVER="http://192.168.x.x:32400"  # Your Plex server IP
PLEX_TOKEN="your_token_here"            # Your Plex authentication token
LIGHTSAIL_IP="10.100.0.1"               # Your remote server WireGuard IP
```

**Getting Your Plex Token:**
1. Open Plex Web (http://your-plex-ip:32400/web)
2. Play any media item
3. Click "..." → "Get Info" → "View XML"
4. Look at the URL for `X-Plex-Token=...`
5. Copy the token value

### 4. Test

Run manually to verify it works:

```bash
/usr/local/bin/plex-quality-manager.sh
```

You should see output showing:
- Current Plex quality setting
- Upload speed test results
- Recommended quality
- Success/failure of quality change

### 5. Set Up Cron Job

Run automatically every 15 minutes:

```bash
crontab -e
```

Add this line:
```
*/15 * * * * /usr/local/bin/plex-quality-manager.sh
```

Save and exit.

## Configuration Options

Edit these variables in the script:

```bash
# Skip bandwidth test if no one is streaming (saves bandwidth)
SKIP_TEST_WHEN_IDLE=true

# How long to run each upload test (seconds)
TEST_DURATION=10

# Log file location
LOG_FILE="/var/log/plex-quality-manager.log"
```

## How It Works

### Quality Selection Algorithm

The script calculates available bandwidth using this logic:

1. **Test Upload Speed** - 10-second iperf3 test through WireGuard tunnel
2. **Apply Safety Margin** - Uses 50% during peak hours (5-11 PM), 65% off-peak
3. **Congestion Penalty** - Reduces by 20% if high retransmissions detected
4. **Subtract Current Usage** - Accounts for active remote streams
5. **Select Quality** - Chooses highest bitrate that fits available bandwidth

### Quality Tiers

| Available Bandwidth | Plex Setting |
|---------------------|--------------|
| 25+ Mbps | 20 Mbps 1080p |
| 18-25 Mbps | 12 Mbps 1080p |
| 13-18 Mbps | 10 Mbps 1080p |
| 10-13 Mbps | 8 Mbps 1080p |
| 7-10 Mbps | 4 Mbps 720p |
| <7 Mbps | 3 Mbps 720p |

### Example Calculation

**Scenario: Peak hours, cable congestion**
- Raw upload test: 16 Mbps
- Peak hour safety (50%): 8 Mbps usable
- High retransmits (80): Apply 20% penalty = 6.4 Mbps
- Current remote stream: 0 Mbps
- **Result: Sets quality to 4 Mbps 720p**

**Scenario: Off-peak, good connection**
- Raw upload test: 28 Mbps
- Off-peak safety (65%): 18.2 Mbps usable
- Low retransmits: No penalty
- Current remote stream: 0 Mbps
- **Result: Sets quality to 12 Mbps 1080p**

## Monitoring

### View Recent Activity

```bash
# Last 50 log entries
tail -50 /var/log/plex-quality-manager.log

# Live monitoring
tail -f /var/log/plex-quality-manager.log
```

### View Quality Changes

```bash
grep "Recommended" /var/log/plex-quality-manager.log | tail -20
```

### View Upload Speed History

```bash
grep "Upload:" /var/log/plex-quality-manager.log | tail -20
```

## Troubleshooting

### Script Not Running

Check cron:
```bash
# View cron logs
grep CRON /var/log/syslog | tail -20

# Verify cron service
sudo systemctl status cron
```

### Cannot Connect to Plex

Test manually:
```bash
curl -s "http://your-plex-ip:32400/?X-Plex-Token=YOUR_TOKEN"
```

Verify:
- Plex server is running
- IP address is correct
- Token is valid
- No firewall blocking

### iperf3 Test Fails

**First, verify WireGuard tunnel:**
```bash
# Check WireGuard interface exists
ip link show wg0

# Check WireGuard is configured
sudo wg show

# Verify tunnel connectivity
ping 10.100.0.1

# If ping fails, WireGuard has a problem - fix that first!
```

**Common WireGuard issues:**
- WireGuard service not running: `sudo systemctl status wg-quick@wg0`
- Firewall blocking: Check UFW/iptables rules
- Endpoint unreachable: Check remote VPS is accessible
- Wrong allowed IPs: Check WireGuard config allows 10.100.0.1/32

**Test iperf3 manually:**
```bash
# This should work if WireGuard is working
iperf3 -c 10.100.0.1 -t 5

# If this fails but ping works, check iperf3 server on remote
```

**Verify iperf3 server is running on remote:**
```bash
# On remote server (Lightsail)
sudo systemctl status iperf3

# Check it's listening
sudo netstat -tulpn | grep 5201
```

**Critical:** If you can't run `iperf3 -c 10.100.0.1` successfully, this script won't work. The machine running the script MUST have WireGuard tunnel access.

### Wrong Machine for Installation

### Wrong Machine for Installation

**Error:** `Cannot reach 10.100.0.1` or `ping: connect: Network is unreachable`

**Cause:** You installed the script on a machine that doesn't have WireGuard configured.

**Solution:**
1. Find which machine has WireGuard: Run `sudo wg show` on each machine
2. Install the script on THAT machine only
3. The machine must have a working tunnel to the remote server

**Example:**
```bash
# On Plex server (192.168.2.215)
sudo wg show
# Output: (nothing - no WireGuard here)

# On WireGuard VM (192.168.2.222)  
sudo wg show
# Output: interface: wg0 ... (WireGuard IS here!)

# Install script on 192.168.2.222, NOT on 192.168.2.215
```

### Quality Not Changing

Enable debug mode:
```bash
# Run script with verbose output
bash -x /usr/local/bin/plex-quality-manager.sh
```

Check Plex settings manually:
```bash
curl -s "http://your-plex-ip:32400/:/prefs?X-Plex-Token=YOUR_TOKEN" | grep WanPerStreamMaxUploadRate
```

## Advanced Usage

### Adjust Safety Margins

Edit `get_safety_margin()` function to change peak/off-peak percentages:

```bash
get_safety_margin() {
    local hour=$(date +%H)
    if [[ $hour -ge 17 && $hour -le 23 ]]; then
        echo "50"  # Peak hours - change this value
    else
        echo "65"  # Off-peak - change this value
    fi
}
```

### Change Quality Thresholds

Edit `get_quality_preset()` function to adjust bandwidth thresholds:

```bash
if awk "BEGIN {exit !($bw >= 25)}"; then
    kbps=20000  # 20 Mbps - adjust threshold or bitrate
elif awk "BEGIN {exit !($bw >= 18)}"; then
    kbps=12000  # 12 Mbps - adjust threshold or bitrate
# ... etc
```

### Run More Frequently During Peak

Edit crontab to run every 10 minutes during peak hours:

```bash
# Every 10 minutes from 5 PM to 11 PM
*/10 17-23 * * * /usr/local/bin/plex-quality-manager.sh

# Every 30 minutes all other times
*/30 0-16,23 * * * /usr/local/bin/plex-quality-manager.sh
```

## Real-World Example

### Before (Static Quality Setting)

**Plex set to 12 Mbps (1080p High):**

```
Monday 3:00 AM  - Upload: 28 Mbps  →  12 Mbps used, 16 Mbps wasted
Monday 8:00 PM  - Upload: 13 Mbps  →  Buffering! (12 Mbps too high)
Monday 9:30 PM  - Upload: 11 Mbps  →  Severe buffering, stream drops
```

**Plex set to 8 Mbps (1080p Medium) - Safe Setting:**

```
Monday 3:00 AM  - Upload: 28 Mbps  →  8 Mbps used, 20 Mbps wasted!
Monday 8:00 PM  - Upload: 13 Mbps  →  Works, but could stream higher
Sunday 2:00 PM  - Upload: 25 Mbps  →  8 Mbps used, 17 Mbps wasted!
```

### After (Dynamic Quality Management)

**Plex Quality Manager automatically adjusts:**

```
Monday 3:00 AM  - Upload: 28 Mbps  →  Set to 12 Mbps (1080p High)
Monday 8:00 PM  - Upload: 13 Mbps  →  Set to 8 Mbps (1080p Medium)
Monday 9:30 PM  - Upload: 11 Mbps  →  Set to 4 Mbps (720p) - No buffering!
Tuesday 11:00 PM - Upload: 22 Mbps  →  Back to 12 Mbps (1080p High)
```

**Result:**
- ✅ No more buffering during peak hours
- ✅ Maximum quality during off-peak hours
- ✅ Automatic adaptation to network conditions
- ✅ No manual intervention needed

## Performance Impact

### WireGuard VM (Ubuntu VM running the script)
- **RAM:** ~5-10MB during test
- **CPU:** ~10 seconds every 15 minutes
- **Network:** 10-second upload test = ~25-35MB per test
- **Disk:** Log file grows ~5KB per run

### Remote Server
- **RAM:** ~5MB for iperf3 server
- **CPU:** Negligible
- **Network:** Receives test traffic only

## Security Notes

- Plex token is stored in plaintext in the script
- Use appropriate file permissions: `chmod 700 /usr/local/bin/plex-quality-manager.sh`
- Consider using environment variables for sensitive data
- WireGuard tunnel encrypts all traffic

## FAQ

**Q: Can I run this on my Plex server directly?**  
A: Only if your Plex server ALSO has the WireGuard tunnel configured. In most setups, WireGuard runs on a separate VM/server, so install there.

**Q: Do all my machines need WireGuard?**  
A: No, only the machine running this script needs WireGuard. Your Plex server doesn't need it - the script just calls the Plex API over your LAN.

**Q: What if I have WireGuard on my router?**  
A: If your router runs WireGuard client, you could potentially install this on the router (if it supports bash/cron). Otherwise, use a dedicated VM.

**Q: Can I use OpenVPN instead of WireGuard?**  
A: Yes! The script just needs to test upload through whatever tunnel you have. Change `LIGHTSAIL_IP` to your OpenVPN tunnel endpoint IP.

**Q: Why not just increase Plex's upload limit setting?**  
A: The "Internet upload speed" setting is different - it's used for local/remote detection. This script adjusts the "Limit remote stream bitrate" setting which actually controls quality.

**Q: Will this work with fiber ISP?**  
A: Yes, but it's most useful for cable/DSL with variable upload speeds.

**Q: Can I use this without WireGuard?**  
A: Yes, but you'll need to modify the upload test to use your actual WAN connection instead of the tunnel.

**Q: Does this affect local streaming?**  
A: No, this only affects the "Limit remote stream bitrate" setting for non-local connections.

**Q: What if I have multiple remote users streaming?**  
A: The script estimates bandwidth per remote stream (8 Mbps average) and accounts for it when setting quality for new streams.

**Q: Can I run this on a Raspberry Pi?**  
A: Yes! It's very lightweight and works great on Pi.

## License

MIT License - See LICENSE file for details

## Contributing

Issues and pull requests welcome!

## Author

Created for managing Plex quality on cable ISP with variable upload speeds through WireGuard VPN tunnel.

## Author

Created by Dan to solve the challenge of streaming Plex through an nginx reverse proxy on AWS Lightsail while dealing with cable ISP upload congestion.

**My Setup:**
- Plex Server on home network (Sidney, Ohio) - 192.168.2.215
- Dedicated Ubuntu VM (1GB RAM) running WireGuard client and this script - 192.168.2.222
  - *This VM also happens to run my DNS server (Technitium), but that's unrelated to this script*
- Spectrum cable ISP (1 Gbps down / 30 Mbps up - but variable)
- AWS Lightsail VPS running nginx reverse proxy + WireGuard server
- WireGuard VPN tunnel (outbound from home VM to Lightsail)
  - Local tunnel IP: 10.100.0.2
  - Remote tunnel IP: 10.100.0.1
- Upload varies 10-30 Mbps based on neighborhood congestion

**Why I Built This:**
- Static quality settings caused buffering during prime time
- Safe settings wasted bandwidth during off-peak hours
- Needed automatic adaptation to cable node congestion
- Wanted to maximize quality without manual intervention

**Architecture Note:**
The script runs on my WireGuard VM (192.168.2.222) because that's where I have WireGuard configured. The script tests upload speed by running iperf3 to the Lightsail tunnel IP (10.100.0.1), then adjusts the quality setting on my Plex server (192.168.2.215) via the Plex API.

## Acknowledgments

- Inspired by the need to work around ISP throttling and port restrictions
- Built for the homelab community running Plex on residential connections
- Special thanks to the Plex and WireGuard communities for excellent tools

## Similar Projects

If this doesn't fit your use case, check out:
- **Tautulli** - Plex monitoring and notification tool
- **Plex Meta Manager** - Advanced Plex library management
- **Organizr** - Unified interface for media services

## Changelog

### v1.0.0 (2026-02-14)
- Initial release
- Automatic quality adjustment based on upload speed
- Peak/off-peak time awareness
- Session-aware bandwidth calculation
- Congestion detection via retransmissions
- Idle optimization to skip tests when no streams active

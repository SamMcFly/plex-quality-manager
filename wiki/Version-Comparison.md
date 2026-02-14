# Version Comparison

Plex Quality Manager comes in two versions. This guide helps you choose.

## Quick Decision Tree

```
Do you have Plex behind a VPN tunnel to a VPS?
├─ YES → Use Bash Version
└─ NO
   └─ Can you run Python on your Plex server?
      ├─ YES → Use Python Version
      └─ NO → Use Bash Version (set up small Ubuntu VM)
```

## Detailed Comparison

| Feature | Bash Version | Python Version |
|---------|--------------|----------------|
| **Upload Test Method** | iperf3 through VPN tunnel | speedtest-cli to internet |
| **Test Duration** | 10 seconds | 30-60 seconds |
| **Test Accuracy** | Excellent (actual tunnel BW) | Good (subject to ISP throttling) |
| **Setup Complexity** | Moderate | Simple |
| **Platform Support** | Linux only | Windows, Linux, macOS |
| **Dependencies** | iperf3, jq, bc, curl | Python 3, 2 packages |
| **Recommended Frequency** | Every 15 minutes | Every 30 minutes |
| **Resource Usage** | Very low | Low-moderate |
| **Best For** | VPN tunnel setups | Simple/direct setups |

## When to Use Bash Version

✅ **Perfect for:**
- Plex behind nginx reverse proxy on VPS
- WireGuard or OpenVPN tunnel from home to VPS
- AWS Lightsail, DigitalOcean, Vultr, etc. setups
- Cable/DSL ISP with variable upload
- Want accurate tunnel bandwidth measurement
- Already have Linux server/VM at home

❌ **Not ideal for:**
- No VPN tunnel setup
- Windows-only environment (no Linux VM)
- Don't have VPS/cloud server
- Want simplest possible setup

## When to Use Python Version

✅ **Perfect for:**
- Plex server directly exposed to internet
- No VPN tunnel
- Can run Python on Plex server
- Want simple one-file installation
- Cross-platform requirement (Windows/Mac)
- ISP doesn't throttle speedtest.net

❌ **Not ideal for:**
- Have VPN tunnel (bash version more accurate)
- Need fastest possible tests
- Want most accurate bandwidth measurement
- ISP throttles speedtest servers

## Technical Differences

### Upload Speed Testing

**Bash Version:**
```bash
# Tests through WireGuard tunnel to remote iperf3 server
iperf3 -c 10.100.0.1 -t 10 -J
# Measures: Actual usable upload through your VPN tunnel
# Duration: 10 seconds
```

**Python Version:**
```python
# Tests to speedtest.net servers
speedtest.upload()
# Measures: WAN upload to internet
# Duration: 30-60 seconds
```

### Accuracy Comparison

**Bash Version (iperf3):**
- ✅ Tests actual path your Plex traffic takes
- ✅ Includes VPN overhead
- ✅ ISP can't throttle (encrypted tunnel)
- ✅ Fast tests (10 sec)
- ❌ Requires VPS setup

**Python Version (speedtest-cli):**
- ✅ Simple to set up
- ✅ No VPS required
- ❌ May not match actual Plex performance
- ❌ ISP may throttle speedtest servers
- ❌ Slower tests (30-60 sec)
- ❌ Doesn't account for VPN overhead

## Migration Between Versions

### From Python to Bash

If you start with Python but later set up a VPN tunnel:

1. Set up VPS with iperf3 (see [Remote Server Setup](Remote-Server-Setup))
2. Set up WireGuard tunnel
3. Install bash version on WireGuard machine
4. Disable Python version cron job
5. Bash version will give more accurate results

### From Bash to Python

If you remove your VPN tunnel setup:

1. Install Python version on Plex server
2. Disable bash version cron job
3. Python version will test direct WAN upload

## Performance Impact

### Bash Version
- **Network:** ~25-35 MB per test (10 sec at 25 Mbps)
- **CPU:** Minimal (~10 sec spike every 15 min)
- **Memory:** ~5-10 MB
- **Frequency:** Every 15 minutes

### Python Version
- **Network:** ~50-200 MB per test (speedtest overhead)
- **CPU:** Moderate (~30-60 sec every 30 min)
- **Memory:** ~50-100 MB
- **Frequency:** Every 30 minutes (recommended)

## Example Setups

### Setup 1: Behind VPS (Use Bash)
```
Internet → VPS (nginx) → WireGuard → Home (Plex)
                              ↓
                        iperf3 tests here
```
**Why bash:** Tests actual tunnel bandwidth

### Setup 2: Direct Plex (Use Python)
```
Internet → Home (Plex)
              ↓
        speedtest here
```
**Why Python:** Simpler, no tunnel to test

### Setup 3: ISP Blocks Ports (Use Bash)
```
Internet → VPS (public IP) → Tunnel → Home (CGNAT)
                                 ↓
                           iperf3 tests here
```
**Why bash:** Need tunnel anyway, get accurate measurement

## Still Not Sure?

**Start with Python version if:**
- You want to try it quickly
- You're not sure about setting up VPS
- You just want to see if it helps

**Then upgrade to Bash version later if:**
- You set up VPN tunnel
- You need more accurate measurements
- You want faster/more frequent tests

Both versions use identical quality adjustment logic - only the upload measurement method differs.

## Next Steps

**Chosen Bash Version?**
→ Go to [Bash Installation Guide](Bash-Installation)

**Chosen Python Version?**
→ Go to [Python Installation Guide](Python-Installation)

**Still deciding?**
→ Check [Example Setups](Example-Setups) for real-world scenarios

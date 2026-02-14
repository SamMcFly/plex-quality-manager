# Welcome to Plex Quality Manager Wiki

Automatically adjust Plex streaming quality based on real-time upload bandwidth.

## 📖 Documentation Index

### Getting Started
- **[Home](Home)** ← You are here
- **[Version Comparison](Version-Comparison)** - Which version should I use?
- **[Quick Start - Bash Version](Quick-Start-Bash)**
- **[Quick Start - Python Version](Quick-Start-Python)**

### Installation Guides
- **[Bash Version Installation](Bash-Installation)** - For VPN tunnel setups
- **[Python Version Installation](Python-Installation)** - For direct Plex setups
- **[Remote Server Setup](Remote-Server-Setup)** - Setting up iperf3 on VPS

### Configuration
- **[Configuration Options](Configuration)** - Customize quality thresholds, margins, etc.
- **[Peak Hours Setup](Peak-Hours)** - Configure time-based safety margins
- **[Quality Tiers](Quality-Tiers)** - Understanding bitrate settings

### Troubleshooting
- **[Common Issues](Troubleshooting)** - Solutions to frequent problems
- **[WireGuard Problems](WireGuard-Troubleshooting)** - Tunnel connectivity issues
- **[Plex API Issues](Plex-API-Troubleshooting)** - Connection and authentication

### Advanced Topics
- **[Multiple Plex Servers](Multiple-Servers)** - Managing multiple instances
- **[Custom Quality Algorithms](Custom-Algorithms)** - Modify quality selection logic
- **[Integration with Tautulli](Tautulli-Integration)** - Enhanced monitoring
- **[Performance Tuning](Performance-Tuning)** - Optimize for your setup

### Examples
- **[Example Setups](Example-Setups)** - Real-world configurations
- **[Log Examples](Log-Examples)** - Understanding the logs

### Contributing
- **[Contributing Guide](Contributing)** - How to contribute
- **[Reporting Bugs](Bug-Reports)** - Issue reporting guidelines

## 🚀 Quick Links

**Choose your version:**
- [Bash Version](Quick-Start-Bash) - For Plex behind VPN tunnel
- [Python Version](Quick-Start-Python) - For direct Plex setup

**Common tasks:**
- [Install on Ubuntu](Bash-Installation#ubuntu-installation)
- [Set up WireGuard](Remote-Server-Setup#wireguard-setup)
- [Get Plex Token](Configuration#getting-plex-token)
- [View Logs](Troubleshooting#viewing-logs)

## 💡 Use Cases

### Scenario 1: Plex Behind VPS
You run Plex at home but use nginx on AWS Lightsail as a reverse proxy with WireGuard tunnel.
→ **Use [Bash Version](Quick-Start-Bash)**

### Scenario 2: Direct Plex
You run Plex exposed directly to the internet (no VPN tunnel).
→ **Use [Python Version](Quick-Start-Python)**

### Scenario 3: ISP Port Restrictions
Your ISP blocks common ports, so you tunnel through a VPS.
→ **Use [Bash Version](Quick-Start-Bash)**

## 🆘 Need Help?

1. Check [Common Issues](Troubleshooting)
2. Review [Example Setups](Example-Setups)
3. [Open an Issue](https://github.com/YOUR_USERNAME/plex-quality-manager/issues)

## 📊 Project Stats

- **Version:** 1.0.0
- **License:** MIT
- **Language:** Bash, Python
- **Platforms:** Linux (Bash), Cross-platform (Python)

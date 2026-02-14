# Welcome to Plex Quality Manager Wiki

Automatically adjust Plex streaming quality based on real-time upload bandwidth.

## 📖 Documentation Index

### Getting Started
- [[Home]] ← You are here
- [[Version Comparison]] - Which version should I use?
- [[Quick Start Bash]]
- [[Quick Start Python]]

### Installation Guides
- [[Bash Installation]] - For VPN tunnel setups
- [[Python Installation]] - For direct Plex setups
- [[Remote Server Setup]] - Setting up iperf3 on VPS

### Configuration
- [[Configuration Options]] - Customize quality thresholds, margins, etc.
- [[Peak Hours Setup]] - Configure time-based safety margins
- [[Quality Tiers]] - Understanding bitrate settings

### Troubleshooting
- [[Common Issues]] - Solutions to frequent problems
- [[WireGuard Problems]] - Tunnel connectivity issues
- [[Plex API Issues]] - Connection and authentication

### Advanced Topics
- [[Multiple Plex Servers]] - Managing multiple instances
- [[Custom Quality Algorithms]] - Modify quality selection logic
- [[Tautulli Integration]] - Enhanced monitoring
- [[Performance Tuning]] - Optimize for your setup

### Examples
- [[Example Setups]] - Real-world configurations
- [[Log Examples]] - Understanding the logs

### Contributing
- [[Contributing Guide]] - How to contribute
- [[Bug Reports]] - Issue reporting guidelines

## 🚀 Quick Links

**Choose your version:**
- [[Quick Start Bash]] - For Plex behind VPN tunnel
- [[Quick Start Python]] - For direct Plex setup

**Common tasks:**
- Getting Plex Token - See [[Configuration Options]]
- View Logs - See [[Troubleshooting]]

## 💡 Use Cases

### Scenario 1: Plex Behind VPS
You run Plex at home but use nginx on AWS Lightsail as a reverse proxy with WireGuard tunnel.
→ **Use [[Quick Start Bash]]**

### Scenario 2: Direct Plex
You run Plex exposed directly to the internet (no VPN tunnel).
→ **Use [[Quick Start Python]]**

### Scenario 3: ISP Port Restrictions
Your ISP blocks common ports, so you tunnel through a VPS.
→ **Use [[Quick Start Bash]]**

## 🆘 Need Help?

1. Check [[Common Issues]]
2. Review [[Example Setups]]
3. Open an issue on GitHub

## 📊 Project Stats

- **Version:** 1.0.0
- **License:** MIT
- **Language:** Bash, Python
- **Platforms:** Linux (Bash), Cross-platform (Python)

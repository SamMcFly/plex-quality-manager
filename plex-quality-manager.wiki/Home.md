# Plex Quality Manager Wiki

Welcome! This wiki contains detailed documentation for Plex Quality Manager.

## Quick Navigation

Use the sidebar to navigate between wiki pages, or see the table of contents below.

## Available Documentation

### Getting Started
- **Home** - This page
- **Version Comparison** - Bash vs Python version comparison
- **Quick Start Bash** - Fast setup guide for Bash version
- **Quick Start Python** - Fast setup guide for Python version

### Installation
- **Bash Installation** - Complete Bash version setup
- **Python Installation** - Complete Python version setup  
- **Remote Server Setup** - Setting up iperf3 on your VPS

### Usage
- **Configuration** - Customize settings
- **Troubleshooting** - Common issues and solutions
- **Log Examples** - Understanding the output

## Version Selector

**Choose your version:**

### Bash Version (Recommended for VPN setups)
Best if you have:
- Plex behind nginx reverse proxy
- WireGuard/OpenVPN tunnel to VPS
- Ubuntu VM on home network
- Cable/DSL with variable upload

See: Quick Start Bash page

### Python Version (Simpler setup)
Best if you have:
- Direct Plex setup (no VPN tunnel)
- Python support on Plex server
- Want easy installation
- Cross-platform requirement

See: Quick Start Python page

## Common Tasks

**Installation:**
- See Quick Start Bash or Quick Start Python pages

**Getting Plex Token:**
1. Open Plex Web at http://your-ip:32400/web
2. Play any media
3. Click ... → Get Info → View XML
4. Copy X-Plex-Token from URL

**Viewing Logs:**
- Bash: `tail -f /var/log/plex-quality-manager.log`
- Python: `tail -f /var/log/plex-quality-manager-python.log`

**Editing Config:**
- Bash: `sudo nano /usr/local/bin/plex-quality-manager.sh`
- Python: `nano /path/to/plex-quality-manager.py`

## Getting Help

1. Check Troubleshooting page
2. Review relevant Quick Start guide
3. Open an issue on GitHub

## Project Info

- **Version:** 1.0.0
- **License:** MIT
- **Languages:** Bash, Python
- **Platforms:** Linux (Bash), Cross-platform (Python)

---

**Note:** Navigate using the wiki sidebar on the right →

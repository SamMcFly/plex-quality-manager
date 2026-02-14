#!/usr/bin/env python3
"""
Plex Quality Manager - Python Version (Direct WAN Testing)

This version tests your actual WAN upload speed directly (no VPN tunnel required)
and adjusts Plex quality accordingly. Suitable for running on the Plex server itself.

Requirements:
    pip install speedtest-cli requests plexapi
"""

import json
import logging
import os
import sys
import time
from datetime import datetime
from pathlib import Path

try:
    import speedtest
    import requests
except ImportError:
    print("ERROR: Missing required packages")
    print("Install with: pip install speedtest-cli requests")
    sys.exit(1)

# ===== CONFIGURATION =====
PLEX_URL = "http://localhost:32400"  # Plex server URL (use localhost if running on Plex server)
PLEX_TOKEN = "YOUR_PLEX_TOKEN_HERE"  # Your Plex authentication token
LOG_FILE = "/var/log/plex-quality-manager-python.log"
SKIP_TEST_WHEN_IDLE = True
USE_SPEEDTEST = True  # Use speedtest-cli (slower but more accurate)
# If False, uses fast.com-style test (faster but requires curl fallback)

# Quality thresholds (Mbps upload -> kbps Plex setting)
QUALITY_MAP = [
    (25, 20000, "20 Mbps 1080p"),
    (18, 12000, "12 Mbps 1080p"),
    (13, 10000, "10 Mbps 1080p"),
    (10, 8000, "8 Mbps 1080p"),
    (7, 4000, "4 Mbps 720p"),
    (0, 3000, "3 Mbps 720p"),
]

# Peak hours (more conservative bandwidth usage)
PEAK_HOURS_START = 17  # 5 PM
PEAK_HOURS_END = 23    # 11 PM
PEAK_SAFETY_MARGIN = 0.50  # Use 50% during peak
OFFPEAK_SAFETY_MARGIN = 0.65  # Use 65% off-peak

# ===== LOGGING SETUP =====
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def get_safety_margin():
    """Get safety margin based on time of day"""
    hour = datetime.now().hour
    if PEAK_HOURS_START <= hour <= PEAK_HOURS_END:
        logger.info("Peak hours - using 50% safety margin")
        return PEAK_SAFETY_MARGIN
    else:
        logger.info("Off-peak - using 65% safety margin")
        return OFFPEAK_SAFETY_MARGIN


def test_upload_speed():
    """Test upload speed using speedtest-cli"""
    logger.info("Testing upload speed (this may take 30-60 seconds)...")
    
    try:
        st = speedtest.Speedtest()
        st.get_best_server()
        
        # Test upload
        upload_bps = st.upload()
        upload_mbps = upload_bps / 1_000_000
        
        logger.info(f"Upload speed: {upload_mbps:.2f} Mbps")
        return upload_mbps
        
    except Exception as e:
        logger.error(f"Speedtest failed: {e}")
        return None


def get_plex_sessions():
    """Get active Plex streaming sessions"""
    try:
        url = f"{PLEX_URL}/status/sessions?X-Plex-Token={PLEX_TOKEN}"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        data = response.text
        
        # Count sessions
        session_count = data.count('<Video ')
        
        if session_count == 0:
            logger.info("No active streams")
            return 0, 0.0
        
        logger.info(f"Active streams: {session_count}")
        
        # Check if remote
        is_local = 'local="1"' in data
        if is_local:
            logger.info("  Session: Local (skipped)")
            return session_count, 0.0
        
        # Get actual bandwidth from Session tag
        import re
        bandwidth_match = re.search(r'Session[^>]*bandwidth="(\d+)"', data)
        
        if bandwidth_match:
            bandwidth_kbps = int(bandwidth_match.group(1))
            bandwidth_mbps = bandwidth_kbps / 1000
            logger.info(f"  Remote session: {bandwidth_mbps:.2f} Mbps (actual bandwidth)")
            return session_count, bandwidth_mbps
        else:
            # Fallback to Media bitrate
            media_match = re.search(r'Media[^>]*bitrate="(\d+)"', data)
            if media_match:
                bitrate_kbps = int(media_match.group(1))
                bitrate_mbps = bitrate_kbps / 1000
                logger.info(f"  Remote session: {bitrate_mbps:.2f} Mbps (media bitrate)")
                return session_count, bitrate_mbps
            else:
                logger.info("  Remote session: 3.00 Mbps (estimated)")
                return session_count, 3.0
                
    except Exception as e:
        logger.warning(f"Could not get streaming sessions: {e}")
        return 0, 0.0


def get_current_quality():
    """Get current Plex quality setting"""
    try:
        url = f"{PLEX_URL}/:/prefs?X-Plex-Token={PLEX_TOKEN}"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        import re
        match = re.search(r'WanPerStreamMaxUploadRate.*?value="(\d+)"', response.text)
        
        if match:
            return int(match.group(1))
        return None
        
    except Exception as e:
        logger.error(f"Could not get current quality: {e}")
        return None


def set_quality(kbps):
    """Set Plex quality"""
    try:
        url = f"{PLEX_URL}/:/prefs?WanPerStreamMaxUploadRate={kbps}&X-Plex-Token={PLEX_TOKEN}"
        response = requests.put(url, timeout=10)
        response.raise_for_status()
        return True
    except Exception as e:
        logger.error(f"Failed to set quality: {e}")
        return False


def get_quality_name(kbps):
    """Get quality name from kbps value"""
    for _, quality_kbps, name in QUALITY_MAP:
        if kbps == quality_kbps:
            return name
    return f"{kbps} kbps"


def calculate_optimal_quality(upload_mbps, current_usage_mbps, safety_margin):
    """Calculate optimal quality based on available bandwidth"""
    
    # Apply safety margin
    usable = upload_mbps * safety_margin
    
    # Subtract current usage
    available = usable - current_usage_mbps
    
    logger.info(f"Upload: {upload_mbps:.2f} Mbps | "
                f"Usable ({int(safety_margin*100)}%): {usable:.2f} Mbps | "
                f"Available: {available:.2f} Mbps")
    
    # Use available if positive, else usable
    bandwidth = available if available > 0 else usable
    
    # Find best quality
    for min_speed, kbps, name in QUALITY_MAP:
        if bandwidth >= min_speed:
            return kbps
    
    # Default to lowest
    return QUALITY_MAP[-1][1]


def main():
    """Main execution"""
    logger.info("=" * 50)
    logger.info("Plex Quality Manager (Python Version)")
    logger.info("=" * 50)
    
    # Verify Plex connection
    try:
        url = f"{PLEX_URL}/?X-Plex-Token={PLEX_TOKEN}"
        response = requests.get(url, timeout=5)
        response.raise_for_status()
    except Exception as e:
        logger.error(f"Cannot connect to Plex at {PLEX_URL}")
        logger.error(f"Error: {e}")
        logger.error("Please check PLEX_URL and PLEX_TOKEN")
        return 1
    
    # Get current quality
    current = get_current_quality()
    if current:
        logger.info(f"Current quality: {get_quality_name(current)}")
    
    # Check sessions
    logger.info("Checking for active streams...")
    session_count, remote_bandwidth = get_plex_sessions()
    
    # Skip if idle
    if SKIP_TEST_WHEN_IDLE and session_count == 0:
        logger.info("Skipping speed test - no active streams")
        logger.info("=" * 50)
        return 0
    
    # Get safety margin
    safety_margin = get_safety_margin()
    
    # Test upload speed
    upload_mbps = test_upload_speed()
    if upload_mbps is None:
        logger.error("Speed test failed - cannot adjust quality")
        return 1
    
    # Calculate optimal quality
    optimal_kbps = calculate_optimal_quality(upload_mbps, remote_bandwidth, safety_margin)
    optimal_name = get_quality_name(optimal_kbps)
    
    logger.info(f"Recommended: {optimal_name}")
    
    # Check if change needed
    if current == optimal_kbps:
        logger.info("Quality already optimal")
        logger.info("=" * 50)
        return 0
    
    # Apply change
    current_name = get_quality_name(current) if current else "unknown"
    logger.info(f"Changing from {current_name} to {optimal_name}...")
    
    if set_quality(optimal_kbps):
        # Verify
        time.sleep(1)
        verify = get_current_quality()
        if verify == optimal_kbps:
            logger.info(f"SUCCESS: Updated to {optimal_name}")
        else:
            logger.warning(f"Set to {optimal_kbps} but shows as {verify}")
    else:
        logger.error("Failed to update quality")
        return 1
    
    logger.info("=" * 50)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("\nInterrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        sys.exit(1)

#!/bin/bash
# Plex Quality Manager - Simplified Bash Version
# Monitors upload speed and adjusts Plex remote quality settings

# ===== CONFIGURATION =====
PLEX_SERVER="http://192.168.x.x:32400"  # Change to your Plex server IP
PLEX_TOKEN="YOUR_PLEX_TOKEN_HERE"       # Get your Plex token (see README)
LIGHTSAIL_IP="10.100.0.1"               # Your remote server WireGuard IP
LOG_FILE="/var/log/plex-quality-manager.log"
TEST_DURATION=10
SKIP_TEST_WHEN_IDLE=true

# ===== FUNCTIONS =====

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${2:-INFO}] $1" | tee -a "$LOG_FILE"
}

get_safety_margin() {
    local hour=$(date +%H)
    if [[ $hour -ge 17 && $hour -le 23 ]]; then
        log_msg "Peak hours - using 50% safety margin" >&2
        echo "50"
    else
        log_msg "Off-peak - using 65% safety margin" >&2
        echo "65"
    fi
}

test_upload() {
    log_msg "Testing upload through tunnel..." >&2
    
    if ! command -v iperf3 &>/dev/null; then
        log_msg "ERROR: iperf3 not found" "ERROR" >&2
        return 1
    fi
    
    if ! ping -c 1 -W 2 "$LIGHTSAIL_IP" &>/dev/null; then
        log_msg "ERROR: Cannot reach $LIGHTSAIL_IP" "ERROR" >&2
        return 1
    fi
    
    local result=$(iperf3 -c "$LIGHTSAIL_IP" -t "$TEST_DURATION" -J 2>&1)
    if [[ $? -ne 0 ]]; then
        log_msg "ERROR: iperf3 failed" "ERROR" >&2
        return 1
    fi
    
    # Parse with jq
    local mbps=$(echo "$result" | jq -r '.end.sum_sent.bits_per_second // 0' | awk '{printf "%.2f", $1/1000000}')
    local retrans=$(echo "$result" | jq -r '.end.sum_sent.retransmits // 0')
    
    log_msg "Upload: $mbps Mbps (Retransmits: $retrans)" >&2
    echo "$mbps $retrans"
}

get_sessions() {
    local response=$(curl -s "$PLEX_SERVER/status/sessions?X-Plex-Token=$PLEX_TOKEN" 2>&1)
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        echo "0 0.00"
        return
    fi
    
    # Count total sessions
    local count=$(echo "$response" | grep -c '<Video ')
    
    if [[ $count -eq 0 ]]; then
        log_msg "No active streams" >&2
        echo "0 0.00"
        return
    fi
    
    log_msg "Active streams: $count" >&2
    
    # Calculate remote bandwidth using Session bandwidth (most accurate)
    local remote_count=0
    local remote_bw=0
    
    # Check if player is remote (local="0" or local not present)
    local is_remote=$(echo "$response" | grep -oP 'Player[^>]*local="\K[^"]+' | head -1)
    
    if [[ "$is_remote" == "1" ]]; then
        log_msg "  Session: Local (skipped)" >&2
        echo "$count 0.00"
        return
    fi
    
    # This is a remote session - get actual bandwidth being used
    # The Session element has bandwidth in kbps
    local session_bw=$(echo "$response" | grep -oP 'Session[^>]*bandwidth="\K[^"]+' | head -1)
    
    if [[ -n "$session_bw" ]] && [[ "$session_bw" -gt 0 ]]; then
        # Convert kbps to Mbps
        remote_bw=$(awk "BEGIN {printf \"%.2f\", $session_bw / 1000}")
        remote_count=1
        log_msg "  Remote session: $remote_bw Mbps (actual bandwidth)" >&2
    else
        # Fallback: try Media bitrate
        local media_bw=$(echo "$response" | grep -oP 'Media[^>]*bitrate="\K[^"]+' | head -1)
        if [[ -n "$media_bw" ]] && [[ "$media_bw" -gt 0 ]]; then
            remote_bw=$(awk "BEGIN {printf \"%.2f\", $media_bw / 1000}")
            remote_count=1
            log_msg "  Remote session: $remote_bw Mbps (media bitrate)" >&2
        else
            # Last resort: estimate
            remote_bw="3.00"
            remote_count=1
            log_msg "  Remote session: 3.00 Mbps (estimated)" >&2
        fi
    fi
    
    log_msg "Total remote: $remote_count stream(s), $remote_bw Mbps" >&2
    echo "$count $remote_bw"
}

get_quality_preset() {
    local upload=$1
    local current_usage=$2
    local retrans=$3
    local margin=$4
    
    # Calculate usable bandwidth
    local usable=$(awk "BEGIN {printf \"%.2f\", $upload * $margin / 100}")
    
    # Apply congestion penalty
    if [[ $retrans -gt 50 ]]; then
        usable=$(awk "BEGIN {printf \"%.2f\", $usable * 0.8}")
        log_msg "Congestion detected ($retrans retrans) - applying penalty" >&2
    fi
    
    # Subtract current usage
    local available=$(awk "BEGIN {printf \"%.2f\", $usable - $current_usage}")
    
    log_msg "Upload: $upload Mbps | Usable ($margin%): $usable Mbps | Available: $available Mbps" >&2
    
    # Use available if positive, else usable
    local bw=$usable
    if awk "BEGIN {exit !($available > 0)}"; then
        bw=$available
    fi
    
    # Determine kbps value based on bandwidth
    # Return kbps value (e.g., 12000 = 12 Mbps)
    local kbps=3000  # Default to 3 Mbps
    
    if awk "BEGIN {exit !($bw >= 25)}"; then
        kbps=20000  # 20 Mbps 1080p
    elif awk "BEGIN {exit !($bw >= 18)}"; then
        kbps=12000  # 12 Mbps 1080p
    elif awk "BEGIN {exit !($bw >= 13)}"; then
        kbps=10000  # 10 Mbps 1080p
    elif awk "BEGIN {exit !($bw >= 10)}"; then
        kbps=8000   # 8 Mbps 1080p
    elif awk "BEGIN {exit !($bw >= 7)}"; then
        kbps=4000   # 4 Mbps 720p
    fi
    
    echo "$kbps"
}

get_quality_name() {
    case $1 in
        20000) echo "20 Mbps 1080p" ;;
        15000) echo "15 Mbps 1080p" ;;
        12000) echo "12 Mbps 1080p" ;;
        10000) echo "10 Mbps 1080p" ;;
        8000) echo "8 Mbps 1080p" ;;
        4000) echo "4 Mbps 720p" ;;
        3000) echo "3 Mbps 720p" ;;
        0) echo "Original (No limit)" ;;
        *) echo "$1 kbps" ;;
    esac
}

get_current_quality() {
    local url="$PLEX_SERVER/:/prefs?X-Plex-Token=$PLEX_TOKEN"
    local response=$(curl -s "$url" 2>&1)
    
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        log_msg "ERROR: Could not get Plex preferences" "ERROR" >&2
        echo ""
        return 1
    fi
    
    # Extract WanPerStreamMaxUploadRate value (in kbps)
    local kbps=$(echo "$response" | grep -oP 'WanPerStreamMaxUploadRate.*?value="\K[^"]+' | head -1)
    
    if [[ -n "$kbps" ]] && [[ "$kbps" =~ ^[0-9]+$ ]]; then
        echo "$kbps"
        return 0
    else
        log_msg "WARNING: Could not extract WanPerStreamMaxUploadRate" "WARN" >&2
        echo ""
        return 1
    fi
}

set_quality() {
    # $1 is kbps value
    curl -s -X PUT "$PLEX_SERVER/:/prefs?WanPerStreamMaxUploadRate=$1&X-Plex-Token=$PLEX_TOKEN" &>/dev/null
    return $?
}

# ===== MAIN =====

log_msg "=========================================="
log_msg "Plex Quality Manager Started"
log_msg "=========================================="

# Test Plex connection
if ! curl -s --max-time 5 "$PLEX_SERVER/?X-Plex-Token=$PLEX_TOKEN" &>/dev/null; then
    log_msg "ERROR: Cannot connect to Plex" "ERROR"
    exit 1
fi

# Get current quality
current=$(get_current_quality)
if [[ -n "$current" ]]; then
    log_msg "Current quality: $(get_quality_name $current)"
else
    log_msg "Could not determine current quality"
fi

# Check sessions
log_msg "Checking for active streams..."
read session_count remote_bw < <(get_sessions)

# Skip if idle
if [[ "$SKIP_TEST_WHEN_IDLE" == "true" && "$session_count" == "0" ]]; then
    log_msg "Skipping test - no active streams"
    log_msg "=========================================="
    exit 0
fi

# Get safety margin
margin=$(get_safety_margin)

# Test upload speed
read upload retrans < <(test_upload)
if [[ -z "$upload" ]]; then
    log_msg "ERROR: Speed test failed" "ERROR"
    exit 1
fi

# Calculate optimal quality
optimal=$(get_quality_preset "$upload" "$remote_bw" "$retrans" "$margin")
log_msg "Recommended: Preset $optimal ($(get_quality_name $optimal))"

# Check if change needed
if [[ "$current" == "$optimal" ]]; then
    log_msg "Quality already optimal"
    log_msg "=========================================="
    exit 0
fi

# Apply change
log_msg "Changing from $(get_quality_name ${current:-0}) to $(get_quality_name $optimal)..."
if set_quality "$optimal"; then
    # Verify the change actually took effect
    sleep 1
    verify=$(get_current_quality)
    if [[ "$verify" == "$optimal" ]]; then
        log_msg "SUCCESS: Updated to $(get_quality_name $optimal)" "SUCCESS"
    else
        log_msg "WARNING: Set to $optimal but shows as $verify" "WARN"
        log_msg "Plex may update on next stream start" "WARN"
    fi
else
    log_msg "ERROR: Failed to update quality" "ERROR"
    exit 1
fi

log_msg "=========================================="
exit 0

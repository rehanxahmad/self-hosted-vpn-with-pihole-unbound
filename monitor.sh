#!/bin/bash

# VPN Server Monitoring Script
# Comprehensive monitoring and alerting for VPN server components

# Configuration
LOG_FILE="/var/log/vpn-monitoring.log"
ALERT_EMAIL=""  # Set email for alerts (optional)
MAX_CPU=80      # CPU usage alert threshold
MAX_MEM=85      # Memory usage alert threshold  
MAX_DISK=90     # Disk usage alert threshold

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

warn() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo -e "${YELLOW}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

# System metrics collection
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'
}

get_memory_usage() {
    free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}'
}

get_disk_usage() {
    df / | tail -1 | awk '{print $5}' | sed 's/%//'
}

# Service status checks
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo "✅ $service: Running"
        return 0
    else
        echo "❌ $service: Not running"
        error "$service is not running"
        return 1
    fi
}

# Network connectivity tests
test_dns_resolution() {
    local test_domain="google.com"

    # Test Unbound (recursive DNS)
    if dig @127.0.0.1 -p 5335 "$test_domain" +short >/dev/null 2>&1; then
        echo "✅ Unbound DNS: Working"
    else
        echo "❌ Unbound DNS: Failed"
        error "Unbound DNS resolution failed"
        return 1
    fi

    # Test PiHole (filtering DNS)
    if dig @127.0.0.1 "$test_domain" +short >/dev/null 2>&1; then
        echo "✅ PiHole DNS: Working"
    else
        echo "❌ PiHole DNS: Failed"
        error "PiHole DNS resolution failed"
        return 1
    fi
}

test_internet_connectivity() {
    if ping -c 3 -W 3 8.8.8.8 >/dev/null 2>&1; then
        echo "✅ Internet: Connected"
        return 0
    else
        echo "❌ Internet: Disconnected"
        error "Internet connectivity failed"
        return 1
    fi
}

# WireGuard specific checks
check_wireguard() {
    if sudo wg show wg0 >/dev/null 2>&1; then
        local peers=$(sudo wg show wg0 peers | wc -l)
        echo "✅ WireGuard: Active ($peers clients configured)"

        # Check if port is listening
        if sudo netstat -ulnp | grep -q ":51820"; then
            echo "✅ WireGuard Port: Listening on 51820/UDP"
        else
            echo "❌ WireGuard Port: Not listening"
            error "WireGuard port 51820 not listening"
        fi
        return 0
    else
        echo "❌ WireGuard: Interface not found"
        error "WireGuard interface wg0 not found"
        return 1
    fi
}

# PiHole specific checks
check_pihole() {
    # Check if PiHole is blocking ads
    local blocked_count=$(pihole -c -e | tail -1 | awk '{print $1}' 2>/dev/null || echo "0")
    local total_queries=$(pihole -c -e | tail -1 | awk '{print $2}' 2>/dev/null || echo "1")

    if [ "$total_queries" -gt 0 ]; then
        local block_percentage=$(( blocked_count * 100 / total_queries ))
        echo "✅ PiHole Blocking: $block_percentage% ($blocked_count/$total_queries queries)"
    else
        echo "⚠️  PiHole: No recent queries"
    fi

    # Check web interface
    if curl -s "http://localhost/admin/" >/dev/null 2>&1; then
        echo "✅ PiHole Web Interface: Accessible"
    else
        echo "❌ PiHole Web Interface: Not accessible"
        warn "PiHole web interface not accessible"
    fi
}

# Resource monitoring
monitor_resources() {
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)

    echo ""
    echo "📊 System Resources:"

    # CPU Check
    if (( $(echo "$cpu_usage > $MAX_CPU" | bc -l) )); then
        echo "⚠️  CPU Usage: ${cpu_usage}% (HIGH)"
        warn "High CPU usage: ${cpu_usage}%"
    else
        echo "✅ CPU Usage: ${cpu_usage}%"
    fi

    # Memory Check
    if (( $(echo "$mem_usage > $MAX_MEM" | bc -l) )); then
        echo "⚠️  Memory Usage: ${mem_usage}% (HIGH)"
        warn "High memory usage: ${mem_usage}%"
    else
        echo "✅ Memory Usage: ${mem_usage}%"
    fi

    # Disk Check
    if [ "$disk_usage" -gt "$MAX_DISK" ]; then
        echo "⚠️  Disk Usage: ${disk_usage}% (HIGH)"
        warn "High disk usage: ${disk_usage}%"
    else
        echo "✅ Disk Usage: ${disk_usage}%"
    fi
}

# Main monitoring function
main() {
    echo "🔍 VPN Server Health Check - $(date)"
    echo "================================================"

    # Service status checks
    echo ""
    echo "🔧 Service Status:"
    check_service "pihole-FTL"
    check_service "unbound" 
    check_service "wg-quick@wg0"

    # Network tests
    echo ""
    echo "🌐 Network Tests:"
    test_internet_connectivity
    test_dns_resolution

    # Component-specific checks
    echo ""
    echo "🛡️  VPN Components:"
    check_wireguard
    check_pihole

    # Resource monitoring
    monitor_resources

    # Network statistics
    echo ""
    echo "📈 Network Statistics:"
    if command -v vnstat >/dev/null 2>&1; then
        echo "📊 Bandwidth Usage (Today):"
        vnstat -i eth0 -d | tail -3 | head -1 | awk '{print "   RX: " $2 " " $3 "  TX: " $5 " " $6}'
    fi

    # Log rotation
    if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then
        tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
        log "Log file rotated (kept last 500 lines)"
    fi

    echo ""
    echo "================================================"
    echo "✅ Health check completed at $(date)"

    log "Health check completed successfully"
}

# Run monitoring
main "$@"

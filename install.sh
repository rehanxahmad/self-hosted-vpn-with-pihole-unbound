#!/bin/bash

# Self-Hosted VPN Server Installation Script
# For Ubuntu 22.04 LTS on AWS EC2
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    error "This script is designed for Ubuntu systems only"
fi

log "Starting VPN Server Installation..."
log "This script will install PiHole, PiVPN (WireGuard), and Unbound"

# Get system information
PUBLIC_IP=$(curl -s https://api.ipify.org)
PRIVATE_IP=$(hostname -I | cut -d' ' -f1)

log "Detected Public IP: $PUBLIC_IP"
log "Detected Private IP: $PRIVATE_IP"

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt install -y curl wget git ufw htop vnstat net-tools dnsutils

# Configure firewall
log "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp comment 'WireGuard VPN'
sudo ufw allow 80/tcp comment 'PiHole Admin Interface'
sudo ufw --force enable

# Install Unbound first (required for PiHole)
log "Installing Unbound recursive DNS resolver..."
sudo apt install -y unbound

# Download root hints
log "Configuring Unbound..."
sudo wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
sudo chown unbound:unbound /var/lib/unbound/root.hints

# Create Unbound configuration
sudo tee /etc/unbound/unbound.conf.d/pi-hole.conf > /dev/null <<EOF
server:
    # Interface and port configuration
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no

    # Root hints file
    root-hints: "/var/lib/unbound/root.hints"

    # Performance tuning
    num-threads: 4
    msg-cache-slabs: 8
    rrset-cache-slabs: 8
    infra-cache-slabs: 8
    key-cache-slabs: 8
    rrset-cache-size: 256m
    msg-cache-size: 128m
    so-rcvbuf: 1m

    # Privacy and security settings
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-below-nxdomain: yes
    harden-referral-path: yes
    unwanted-reply-threshold: 10000000

    # Performance optimizations
    prefetch: yes
    prefetch-key: yes
    target-fetch-policy: "3 2 1 0 0"

    # Access control - allow local networks
    access-control: 127.0.0.1/32 allow
    access-control: 10.0.0.0/8 allow
    access-control: 172.16.0.0/12 allow
    access-control: 192.168.0.0/16 allow
EOF

# Start and enable Unbound
sudo systemctl start unbound
sudo systemctl enable unbound

# Test Unbound
log "Testing Unbound configuration..."
dig @127.0.0.1 -p 5335 google.com +short > /dev/null || error "Unbound test failed"

# Create PiHole setup vars for unattended installation
log "Preparing PiHole installation..."
sudo mkdir -p /etc/pihole

sudo tee /etc/pihole/setupVars.conf > /dev/null <<EOF
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=${PRIVATE_IP}/24
IPV6_ADDRESS=
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=127.0.0.1#5335
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=local
WEBPASSWORD=
BLOCKING_ENABLED=true
EOF

# Install PiHole
log "Installing PiHole..."
curl -sSL https://install.pi-hole.net | sudo bash /dev/stdin --unattended

# Configure PiHole to use Unbound
log "Configuring PiHole to use Unbound..."
sudo pihole -a setdns 127.0.0.1#5335

# Restart PiHole DNS
sudo pihole restartdns

# Install PiVPN
log "Installing PiVPN with WireGuard..."

# Create PiVPN setup vars
sudo mkdir -p /etc/pivpn

sudo tee /etc/pivpn/setupVars.conf > /dev/null <<EOF
UNATTUPG=1
SUDOUSER=ubuntu
PLAT=Ubuntu
OSCN=jammy
USING_UFW=1
IPV4_ADDRESS=${PRIVATE_IP}
INSTALL_USER=ubuntu
VPN=wireguard
pivpnNET=10.6.0.0
subnetClass=24
ALLOWED_IPS="0.0.0.0/0, ::0/0"
pivpnMTU=1420
pivpnPORT=51820
pivpnDNS1=127.0.0.1
pivpnDNS2=1.1.1.1
pivpnSEARCHDOMAIN=
pivpnHOST=${PUBLIC_IP}
INPUT_CHAIN_EDITED=
FORWARD_CHAIN_EDITED=
pivpnPROTO=udp
pivpnENCRYPTION=256
DOWNLOAD_DH_PARAM=0
PUBLICDNS=1.1.1.1
OVPNDNS1=127.0.0.1
OVPNDNS2=1.1.1.1
EOF

# Download and install PiVPN
curl -L https://install.pivpn.io | sudo bash /dev/stdin --unattended

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Set up automatic updates
log "Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Create health check script
log "Creating health monitoring script..."
sudo tee /usr/local/bin/vpn-health-check.sh > /dev/null <<'EOF'
#!/bin/bash
# VPN Server Health Check Script

echo "=== VPN Server Health Check ==="
echo "Date: $(date)"
echo ""

# Check WireGuard status
echo "WireGuard Status:"
sudo wg show
echo ""

# Check PiHole status  
echo "PiHole Status:"
pihole status
echo ""

# Check Unbound status
echo "Unbound Status:"
sudo systemctl is-active unbound
echo ""

# Check disk usage
echo "Disk Usage:"
df -h / | tail -n +2
echo ""

# Check memory usage
echo "Memory Usage:"
free -h
echo ""

# Network connectivity test
echo "Network Connectivity Test:"
ping -c 3 -W 3 8.8.8.8 >/dev/null 2>&1 && echo "✅ Internet: OK" || echo "❌ Internet: FAILED"
echo ""

# DNS resolution test
echo "DNS Resolution Test:"
dig @127.0.0.1 -p 5335 google.com +short >/dev/null 2>&1 && echo "✅ Unbound: OK" || echo "❌ Unbound: FAILED"
dig @127.0.0.1 google.com +short >/dev/null 2>&1 && echo "✅ PiHole: OK" || echo "❌ PiHole: FAILED"
EOF

sudo chmod +x /usr/local/bin/vpn-health-check.sh

# Set up daily health check
echo "0 6 * * * /usr/local/bin/vpn-health-check.sh > /var/log/vpn-health.log 2>&1" | sudo crontab -

# Create client management script
log "Creating client management utilities..."
sudo tee /usr/local/bin/vpn-client > /dev/null <<'EOF'
#!/bin/bash
# VPN Client Management Script

case "$1" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: vpn-client add <client-name>"
            exit 1
        fi
        sudo pivpn add -n "$2"
        ;;
    remove)
        sudo pivpn remove
        ;;
    list)
        sudo pivpn list
        ;;
    qr)
        if [ -z "$2" ]; then
            echo "Usage: vpn-client qr <client-name>"
            exit 1
        fi
        sudo pivpn -qr "$2"
        ;;
    stats)
        sudo pivpn -c
        ;;
    *)
        echo "VPN Client Management"
        echo "Usage: $0 {add|remove|list|qr|stats} [client-name]"
        echo ""
        echo "Commands:"
        echo "  add <name>    - Add new VPN client"
        echo "  remove        - Remove VPN client (interactive)"
        echo "  list          - List all VPN clients"
        echo "  qr <name>     - Show QR code for client"
        echo "  stats         - Show client statistics"
        exit 1
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/vpn-client

# Generate random PiHole admin password
PIHOLE_PASSWORD=$(openssl rand -base64 32)
echo "$PIHOLE_PASSWORD" | sudo pihole -a -p

# Final configuration summary
log "Installation completed successfully!"
echo ""
echo "======================================"
echo "🎉 VPN SERVER SETUP COMPLETE!"
echo "======================================"
echo ""
echo "📊 Server Information:"
echo "  Public IP: $PUBLIC_IP"
echo "  Private IP: $PRIVATE_IP"
echo "  WireGuard Port: 51820/UDP"
echo ""
echo "🔐 PiHole Admin Interface:"
echo "  URL: http://$PUBLIC_IP/admin"
echo "  Password: $PIHOLE_PASSWORD"
echo ""
echo "⚠️  IMPORTANT: Save the PiHole password above!"
echo ""
echo "🔧 Next Steps:"
echo "1. Create VPN client: vpn-client add <device-name>"
echo "2. Get QR code: vpn-client qr <device-name>"
echo "3. Install WireGuard app on your devices"
echo "4. Test connection and DNS blocking"
echo ""
echo "📋 Useful Commands:"
echo "  vpn-client list          - List VPN clients"
echo "  vpn-client add phone     - Add client named 'phone'"
echo "  vpn-client qr phone      - Show QR code for 'phone'"
echo "  sudo /usr/local/bin/vpn-health-check.sh - Run health check"
echo ""
echo "📖 Full documentation: https://github.com/yourusername/self-hosted-vpn"
echo "======================================"

# Save installation info
sudo tee /var/log/vpn-install-info.txt > /dev/null <<EOF
VPN Server Installation Completed: $(date)
Public IP: $PUBLIC_IP
Private IP: $PRIVATE_IP
PiHole Admin Password: $PIHOLE_PASSWORD
Installation Script Version: 1.0
EOF

log "Installation information saved to /var/log/vpn-install-info.txt"

#!/bin/bash

# VPN Server Backup Script
# Creates comprehensive backup of all VPN server configurations

set -e

# Configuration
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vpn-server-backup-$DATE.tar.gz"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting VPN server backup..."

# Create temporary directory for backup files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Backup PiHole configuration
log "Backing up PiHole configuration..."
sudo mkdir -p "$TEMP_DIR/pihole"
sudo cp -r /etc/pihole/* "$TEMP_DIR/pihole/" 2>/dev/null || warn "Some PiHole files could not be copied"

# Export PiHole settings
sudo pihole -a -t "$TEMP_DIR/pihole/pihole-backup.tar.gz" || warn "PiHole teleporter backup failed"

# Backup WireGuard configuration
log "Backing up WireGuard configuration..."
sudo mkdir -p "$TEMP_DIR/wireguard"
sudo cp -r /etc/wireguard/* "$TEMP_DIR/wireguard/" 2>/dev/null || warn "Some WireGuard files could not be copied"

# Backup Unbound configuration
log "Backing up Unbound configuration..."
sudo mkdir -p "$TEMP_DIR/unbound"
sudo cp -r /etc/unbound/unbound.conf.d/* "$TEMP_DIR/unbound/" 2>/dev/null || warn "Some Unbound files could not be copied"

# Backup system configuration
log "Backing up system configuration..."
sudo mkdir -p "$TEMP_DIR/system"
sudo cp /etc/sysctl.conf "$TEMP_DIR/system/" 2>/dev/null || warn "sysctl.conf not copied"
sudo ufw status verbose > "$TEMP_DIR/system/ufw-rules.txt" 2>/dev/null || warn "UFW rules not exported"

# Create system info file
log "Collecting system information..."
cat > "$TEMP_DIR/system/system-info.txt" <<EOF
VPN Server Backup Information
Generated: $(date)
System: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Public IP: $(curl -s https://api.ipify.org || echo "Unable to detect")
Private IP: $(hostname -I | cut -d' ' -f1)

Installed Packages:
$(dpkg -l | grep -E "(pihole|wireguard|unbound)" || echo "No relevant packages found")

Running Services:
$(systemctl is-active pihole-FTL) - PiHole
$(systemctl is-active wg-quick@wg0) - WireGuard  
$(systemctl is-active unbound) - Unbound

Disk Usage:
$(df -h /)

Memory Usage:
$(free -h)
EOF

# Create restore instructions
cat > "$TEMP_DIR/RESTORE_INSTRUCTIONS.txt" <<EOF
VPN Server Restore Instructions
===============================

This backup contains configurations for:
- PiHole (DNS filtering and ad blocking)
- WireGuard (VPN server)
- Unbound (recursive DNS resolver)
- System configurations

To restore from this backup:

1. Set up a fresh Ubuntu 22.04 server
2. Run the installation script: ./install.sh
3. Stop services:
   sudo systemctl stop pihole-FTL
   sudo systemctl stop wg-quick@wg0
   sudo systemctl stop unbound

4. Restore configurations:
   sudo cp -r pihole/* /etc/pihole/
   sudo cp -r wireguard/* /etc/wireguard/
   sudo cp -r unbound/* /etc/unbound/unbound.conf.d/

5. Set proper permissions:
   sudo chown -R pihole:pihole /etc/pihole/
   sudo chown -R root:root /etc/wireguard/
   sudo chmod 600 /etc/wireguard/wg0.conf
   sudo chown -R unbound:unbound /etc/unbound/

6. Restart services:
   sudo systemctl start unbound
   sudo systemctl start pihole-FTL
   sudo systemctl start wg-quick@wg0

7. Verify all services are running:
   sudo systemctl status pihole-FTL
   sudo systemctl status wg-quick@wg0
   sudo systemctl status unbound

IMPORTANT: Update any IP addresses in configurations if restoring to different server!
EOF

# Change ownership to ubuntu user
sudo chown -R ubuntu:ubuntu "$TEMP_DIR"

# Create compressed backup
log "Creating compressed backup archive..."
cd "$TEMP_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_FILE" .
cd - > /dev/null

# Set permissions
chmod 600 "$BACKUP_DIR/$BACKUP_FILE"

# Clean up old backups (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "vpn-server-backup-*.tar.gz" -mtime +7 -delete 2>/dev/null || warn "Could not clean old backups"

# Display results
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
log "Backup completed successfully!"
echo ""
echo "📁 Backup Details:"
echo "   File: $BACKUP_FILE"
echo "   Size: $BACKUP_SIZE"
echo "   Location: $BACKUP_DIR/"
echo ""
echo "💾 To download backup to local machine:"
echo "   scp -i your-key.pem ubuntu@your-server:$BACKUP_DIR/$BACKUP_FILE ."
echo ""
echo "🔄 To restore from backup, extract and follow RESTORE_INSTRUCTIONS.txt"

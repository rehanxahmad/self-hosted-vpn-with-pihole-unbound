# Security Guidelines

## 🔐 Security Overview

This self-hosted VPN server prioritizes security and privacy. This document outlines security considerations, best practices, and recommendations for maintaining a secure deployment.

## 🛡️ Security Features

### Built-in Security
- **WireGuard Encryption**: State-of-the-art VPN protocol with ChaCha20 encryption
- **DNS Privacy**: Unbound recursive DNS prevents upstream logging
- **Network Isolation**: VPN clients isolated from each other
- **Ad/Malware Blocking**: PiHole blocks malicious domains
- **Minimal Attack Surface**: Only necessary ports exposed

### Infrastructure Security
- **AWS Security Groups**: Restrict access to essential ports only
- **UFW Firewall**: Host-level firewall protection
- **Regular Updates**: Automated security updates enabled
- **Key-based SSH**: Password authentication disabled

## 🔒 Security Best Practices

### Server Hardening

#### 1. SSH Security
```bash
# Disable password authentication
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PermitRootLogin no
# Set: Protocol 2

# Restart SSH service
sudo systemctl restart ssh

# Use SSH keys only
chmod 600 ~/.ssh/authorized_keys
```

#### 2. Firewall Configuration
```bash
# Review and tighten firewall rules
sudo ufw status verbose

# Only allow necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp  # WireGuard
sudo ufw allow 80/tcp     # PiHole admin (consider restricting IP)
```

#### 3. System Updates
```bash
# Enable automatic security updates
sudo dpkg-reconfigure unattended-upgrades

# Manual update check
sudo apt update && sudo apt list --upgradable
```

### VPN Security

#### 1. WireGuard Key Management
```bash
# Generate new server keys periodically
wg genkey | tee server_private_key | wg pubkey > server_public_key

# Rotate client keys regularly
sudo pivpn remove old_client
sudo pivpn add -n new_client_name
```

#### 2. Client Configuration Security
- Store client configurations securely
- Use unique keys for each device
- Remove unused client configurations
- Enable automatic key rotation if possible

#### 3. DNS Security
```bash
# Verify Unbound is only listening locally
sudo netstat -tlnp | grep :5335

# Check PiHole DNS settings
pihole -a -i local  # Set interface listening to local only
```

## 🚨 Security Monitoring

### Log Monitoring
```bash
# Monitor authentication attempts
sudo tail -f /var/log/auth.log

# Check for suspicious network activity
sudo netstat -nat | grep :51820

# Review PiHole query logs for unusual patterns
tail -f /var/log/pihole.log
```

### Automated Monitoring
```bash
# Install fail2ban for intrusion prevention
sudo apt install fail2ban

# Configure fail2ban for SSH
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

### Security Auditing
```bash
# Check for rootkits
sudo apt install rkhunter
sudo rkhunter --check

# Monitor file changes
sudo apt install aide
sudo aide --init
sudo aide --check
```

## 🔍 Vulnerability Management

### Regular Security Assessments

#### 1. Port Scanning
```bash
# External port scan (from different network)
nmap -sS -O target_ip

# Internal service check
sudo netstat -tlnp
```

#### 2. SSL/TLS Configuration
```bash
# Test PiHole admin interface SSL (if enabled)
openssl s_client -connect your_server:443

# Consider enabling HTTPS for PiHole admin
sudo nano /etc/lighttpd/lighttpd.conf
```

#### 3. Network Security
```bash
# Monitor network connections
sudo ss -tulpn

# Check for unusual processes
sudo ps aux | grep -E "(pihole|wireguard|unbound)"
```

### Update Management
- **Critical Updates**: Apply immediately
- **Security Updates**: Weekly review and application
- **Feature Updates**: Monthly review and testing
- **System Reboot**: Schedule during maintenance windows

## 🔐 Access Control

### Multi-Factor Authentication
Consider implementing additional authentication layers:

#### 1. SSH Key + Passphrase
```bash
# Generate SSH key with passphrase
ssh-keygen -t ed25519 -C "your_email@example.com"
# Enter passphrase when prompted
```

#### 2. PiHole Admin Protection
```bash
# Change default admin password regularly
pihole -a -p

# Consider restricting admin access by IP
sudo ufw allow from YOUR_IP to any port 80
```

### Client Access Management
```bash
# Regular client audit
sudo pivpn list

# Remove inactive clients
sudo pivpn remove

# Monitor client connections
sudo wg show
```

## 🛡️ Incident Response

### Security Incident Procedures

#### 1. Immediate Response
1. **Isolate**: Disconnect compromised systems
2. **Assess**: Determine scope of compromise
3. **Contain**: Prevent further damage
4. **Document**: Record all actions taken

#### 2. Investigation Steps
```bash
# Check for unauthorized access
sudo lastlog
sudo last

# Review system logs
sudo journalctl --since "1 hour ago"

# Check for modified files
sudo find /etc /usr/local/bin -type f -mtime -1
```

#### 3. Recovery Actions
```bash
# Rotate all credentials
sudo pivpn remove_all  # Remove all clients
# Regenerate server keys
# Create new client configurations

# Update and patch system
sudo apt update && sudo apt upgrade

# Review and tighten security configurations
```

### Backup Security
```bash
# Encrypt backups
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# Secure backup storage
chmod 600 encrypted_backup.gpg
```

## 📋 Security Checklist

### Initial Setup Security
- [ ] SSH key-based authentication configured
- [ ] Root login disabled
- [ ] Firewall rules properly configured
- [ ] Only necessary ports exposed
- [ ] Strong passwords set for all accounts
- [ ] Automatic security updates enabled

### Ongoing Security Maintenance
- [ ] Regular security updates applied
- [ ] Client access reviewed monthly
- [ ] Log files monitored for anomalies
- [ ] Backup integrity verified
- [ ] SSL certificates renewed (if applicable)
- [ ] Security scanning performed quarterly

### Emergency Preparedness
- [ ] Incident response plan documented
- [ ] Emergency contacts identified
- [ ] Backup restoration tested
- [ ] Recovery procedures documented
- [ ] Alternative access methods available

## 🚨 Reporting Security Issues

### Responsible Disclosure
If you discover a security vulnerability:

1. **Do not** create a public GitHub issue
2. **Do** email the security contact directly
3. **Include** detailed information about the vulnerability
4. **Allow** reasonable time for response and fix
5. **Coordinate** disclosure timeline

### Security Contact
- **Email**: security@yourproject.com
- **PGP Key**: [Include PGP key fingerprint]
- **Response Time**: Within 48 hours

## 📚 Security Resources

### Additional Reading
- [WireGuard Security Model](https://www.wireguard.com/papers/wireguard.pdf)
- [Pi-hole Security Best Practices](https://docs.pi-hole.net/main/security/)
- [AWS EC2 Security Guidelines](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security.html)
- [Ubuntu Security Documentation](https://ubuntu.com/security)

### Security Tools
- **Nmap**: Network discovery and security auditing
- **Fail2ban**: Intrusion prevention system
- **AIDE**: Advanced Intrusion Detection Environment
- **rkhunter**: Rootkit scanner
- **Wireshark**: Network protocol analyzer

---

**Remember**: Security is an ongoing process, not a one-time setup. Regular monitoring, updates, and assessment are essential for maintaining a secure VPN server.

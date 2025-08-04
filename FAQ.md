# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is this project about?
**A:** This project provides a complete guide and automation scripts to set up your own private VPN server using PiHole (ad blocker), PiVPN (WireGuard), and Unbound (DNS resolver) on AWS EC2. It gives you complete control over your internet privacy without relying on commercial VPN providers.

### Q: How much does it cost to run?
**A:** 
- **First 12 months**: Free (AWS Free Tier)
- **After free tier**: $8-12/month depending on usage
- **Data transfer**: Free tier includes 30GB/month outbound
- Much cheaper than commercial VPN services ($10-15/month)

### Q: Is this suitable for beginners?
**A:** Yes! The installation script automates most of the process. You need basic familiarity with:
- SSH/Terminal commands
- AWS console navigation  
- Installing apps on your devices

## Technical Questions

### Q: What's the difference between split tunneling and full tunneling?
**A:**
- **Split Tunneling**: Only DNS traffic goes through VPN (bandwidth efficient, free tier friendly)
- **Full Tunneling**: All internet traffic routed through VPN (maximum privacy, uses more data)

### Q: Can I use this for streaming services?
**A:** Yes, but:
- Full tunneling works better for geo-blocking bypass
- Some streaming services block VPN traffic
- Consider data usage limits on AWS free tier

### Q: How many devices can connect?
**A:** Unlimited! WireGuard supports multiple simultaneous connections. The t2.micro instance can handle 10-20 devices without issues.

### Q: Will this work outside my home country?
**A:** Yes! Since it's running on AWS cloud infrastructure, you can connect from anywhere with internet access.

## Setup and Installation

### Q: Which AWS region should I choose?
**A:** Choose the region closest to your location for best performance:
- **US East (N. Virginia)** - us-east-1
- **Europe (Ireland)** - eu-west-1  
- **Asia Pacific (Singapore)** - ap-southeast-1

### Q: Can I use other cloud providers?
**A:** The scripts are designed for Ubuntu 22.04, so they should work on:
- Google Cloud Platform (GCP)
- Microsoft Azure
- DigitalOcean
- Linode
- Any Ubuntu 22.04 VPS

### Q: What if I already have a VPS running other services?
**A:** The installation script is designed for clean Ubuntu installations. If you have other services running:
1. Create a backup first
2. Review the script before running
3. Consider using a separate VPS for the VPN server

### Q: How long does installation take?
**A:** 
- Manual setup: 1-2 hours
- Automated script: 15-20 minutes
- Client configuration: 5 minutes per device

## Configuration and Usage

### Q: How do I add new devices?
**A:**
```bash
# SSH into your server
ssh -i your-key.pem ubuntu@your-server-ip

# Add new client
sudo pivpn add -n device-name

# Get QR code for mobile devices
sudo pivpn -qr device-name

# Download config for computers
scp -i your-key.pem ubuntu@your-server-ip:~/configs/device-name.conf ./
```

### Q: How do I check if ad blocking is working?
**A:**
1. Visit the PiHole admin interface: `http://your-server-ip/admin`
2. Check the dashboard for blocked queries
3. Test with ad-heavy websites
4. Use online ad-block tests

### Q: Can I customize the blocklists?
**A:** Yes! In the PiHole admin interface:
1. Go to "Group Management" → "Adlists"
2. Add custom blocklist URLs
3. Update gravity: "Tools" → "Update Gravity"

Popular additional blocklists:
- StevenBlack hosts file
- Energized Protection
- OISD blocklists

### Q: How do I access my home network remotely?
**A:** You'll need to configure your home router to allow VPN connections to your local network. This requires:
1. Port forwarding on your home router
2. Static IP or dynamic DNS
3. Additional security considerations

## Troubleshooting

### Q: VPN connects but no internet access
**A:** Check these common issues:
1. **DNS Settings**: Ensure client is using 10.6.0.1 as DNS
2. **Firewall**: Verify port 51820/UDP is open
3. **IP Forwarding**: Run `sudo sysctl net.ipv4.ip_forward=1`
4. **Service Status**: Check `sudo systemctl status wg-quick@wg0`

### Q: PiHole admin page not accessible
**A:**
1. Check if lighttpd is running: `sudo systemctl status lighttpd`
2. Verify firewall allows port 80: `sudo ufw status`
3. Try accessing from VPN IP: `http://10.6.0.1/admin`

### Q: High data usage charges on AWS
**A:**
1. **Enable Split Tunneling**: Modify client configs to only route DNS
2. **Monitor Usage**: Set up AWS billing alerts
3. **Consider Lightsail**: Fixed-price alternative for high usage

### Q: DNS resolution is slow
**A:**
1. **Check Unbound**: `dig @127.0.0.1 -p 5335 google.com`
2. **Clear DNS Cache**: `sudo pihole restartdns`
3. **Optimize Unbound**: Increase cache sizes in config
4. **Check Network Latency**: Use `ping` to test connectivity

### Q: Client can't connect to VPN
**A:**
1. **Verify Config**: Check client configuration file
2. **Test Port**: `telnet your-server-ip 51820`
3. **Check Logs**: `sudo journalctl -u wg-quick@wg0`
4. **Firewall Rules**: Ensure security group allows UDP 51820

## Security and Privacy

### Q: Is this more secure than commercial VPN providers?
**A:** It depends on your threat model:

**Advantages:**
- You control all data and logs
- No shared infrastructure with other users
- Open source components
- Full visibility into configuration

**Considerations:**
- You're responsible for security updates
- Single server vs. provider's multiple servers
- Your AWS account could be compromised

### Q: Are there any logs kept?
**A:** By default:
- **WireGuard**: No connection logs
- **PiHole**: DNS query logs (can be disabled)
- **Unbound**: No query logs
- **System**: Standard Linux system logs

You can disable DNS logging: `pihole -l off`

### Q: What happens if my server is compromised?
**A:**
1. **Immediate**: Change all passwords and keys
2. **Investigation**: Review logs for unauthorized access
3. **Recovery**: Restore from backup or rebuild server
4. **Prevention**: Follow security hardening guide

### Q: Should I enable automatic updates?
**A:** Yes, for security updates:
```bash
# Security updates only (recommended)
sudo dpkg-reconfigure unattended-upgrades

# Manual major updates to avoid breaking changes
```

## Maintenance and Management

### Q: How often should I update the server?
**A:**
- **Security Updates**: Automatic (weekly)
- **System Updates**: Monthly review
- **Component Updates**: Quarterly (PiHole, WireGuard)
- **Full System**: Semi-annually or as needed

### Q: How do I backup my configuration?
**A:**
```bash
# Run the backup script
sudo ./backup.sh

# Download backup to local machine
scp -i your-key.pem ubuntu@your-server-ip:~/backups/latest-backup.tar.gz ./
```

### Q: Can I monitor server performance?
**A:**
```bash
# Run health check
sudo ./monitor.sh

# Check resource usage
htop
df -h
free -m

# Monitor network usage
vnstat -i eth0
```

### Q: What if I want to migrate to a different server?
**A:**
1. Create backup of current server
2. Launch new server
3. Run installation script
4. Restore configuration from backup
5. Update client configurations with new server IP

## Cost Optimization

### Q: How can I minimize AWS costs?
**A:**
1. **Use Free Tier**: Stay within limits for first 12 months
2. **Split Tunneling**: Reduce data transfer costs
3. **Monitor Usage**: Set up billing alerts
4. **Right-size Instance**: t2.micro is sufficient for most users
5. **Reserved Instances**: For long-term usage (1+ years)

### Q: What are the data transfer limits?
**A:**
- **Free Tier**: 30GB outbound per month
- **After Free Tier**: $0.09/GB for additional transfer
- **Split Tunnel**: Uses minimal data (DNS queries only)
- **Full Tunnel**: All browsing data counts toward limit

### Q: Is there a cheaper alternative to AWS?
**A:** Yes, consider:
- **DigitalOcean**: $5/month droplet
- **Linode**: $5/month VPS
- **Vultr**: $3.50-6/month instances
- **AWS Lightsail**: $3.50/month (includes 1TB transfer)

## Advanced Usage

### Q: Can I run multiple VPN servers?
**A:** Yes! You can:
- Run servers in different AWS regions
- Load balance between servers
- Have separate servers for different purposes
- Use DNS-based failover

### Q: How do I set up custom DNS blocking?
**A:**
1. Access PiHole admin interface
2. Go to "Domains" → "Blacklist"
3. Add specific domains or wildcards
4. Create custom blocklist files

### Q: Can I integrate with home automation?
**A:** Yes! You can:
- Use PiHole API for automation
- Monitor VPN status with scripts
- Integrate with monitoring systems
- Create custom dashboards

### Q: How do I enable IPv6 support?
**A:** IPv6 support requires additional configuration:
1. Enable IPv6 in AWS VPC
2. Configure WireGuard for IPv6
3. Update PiHole for IPv6 filtering
4. Test IPv6 connectivity

## Getting Help

### Q: Where can I get support?
**A:**
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community help
- **Documentation**: Comprehensive guides and troubleshooting
- **Community**: User-contributed solutions and tips

### Q: How do I report bugs or request features?
**A:**
1. Search existing GitHub issues first
2. Create detailed bug report with:
   - System information
   - Steps to reproduce
   - Error messages and logs
   - Expected vs actual behavior

### Q: Can I contribute to the project?
**A:** Absolutely! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code contributions
- Documentation improvements
- Testing and bug reports
- Feature suggestions

### Q: Is commercial support available?
**A:** Currently, support is community-based through GitHub. For enterprise or commercial deployments, consider:
- Professional consulting services
- Managed VPN solutions
- Enterprise support contracts

---

**Still have questions?** 
- Check the [main documentation](README.md)
- Search [GitHub issues](https://github.com/yourusername/self-hosted-vpn/issues)
- Start a [discussion](https://github.com/yourusername/self-hosted-vpn/discussions)

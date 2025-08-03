# Complete Installation Guide

**Production-ready deployment guide for Amir Salahshur's Portfolio from fresh Ubuntu server to live website**

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS (recommended)
- **CPU**: 1 vCPU (2+ recommended for production)
- **RAM**: 2GB (4GB+ recommended)
- **Storage**: 20GB free space (50GB+ recommended)
- **Network**: Public IP address with domain name

### Software Requirements
- **Node.js**: 20.0.0 or higher (automatically installed)
- **npm**: 9.0.0 or higher (comes with Node.js)
- **PM2**: Latest version (automatically installed)
- **Nginx**: Latest version (automatically installed)
- **Git**: Latest version (automatically installed)

### Domain Requirements
- Domain name pointing to server IP (A record)
- DNS propagation completed (allow 24-48 hours)
- **Subdomain Support**: Multi-level subdomains supported (e.g., `info.example.com`, `api.v2.example.com`)
- Optional: WWW subdomain setup

> **⚠️ Important**: Ensure your domain's A record points to your server's IP address before starting installation.

---

## 🚀 Quick Installation (One Command)

For a complete automated installation on a fresh Ubuntu server:

### Standard Domain Installation
```bash
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com
```

### Subdomain Installation
For subdomains (e.g., `info.example.com`, `portfolio.yourname.com`), use the `--skip-domain-check` flag:

```bash
# For subdomains, use --skip-domain-check flag
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- info.amirsalahshur.xyz your-email@domain.com --skip-domain-check
```

### Additional Options
```bash
# Preview installation (dry run)
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com --dry-run

# Force reinstallation over existing installation
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com --force
```

**What this does:**
1. Installs all prerequisites (Node.js 20+, PM2, Nginx)
2. Creates portfolio user and directories
3. Clones the repository
4. Builds the application
5. Configures systemd service
6. Sets up Nginx with SSL
7. Starts the application

### 📋 Pre-Installation Checklist

Before running the installation, ensure:

- [ ] **Domain DNS is configured**: A record points to your server IP
- [ ] **For subdomains**: Parent domain exists and subdomain A record is set
- [ ] **Server access**: You have root/sudo access to the server
- [ ] **Port availability**: Ports 80 and 443 are not in use by other services
- [ ] **System resources**: At least 2GB RAM and 20GB storage available
- [ ] **Fresh server**: Ubuntu 20.04+ or 22.04+ (recommended)

> **💡 Tip**: Test your domain first with `ping your-domain.com` to verify DNS propagation.

---

## 📖 Manual Installation

### Step 1: Server Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git build-essential software-properties-common

# Configure timezone
sudo timedatectl set-timezone UTC

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### Step 2: Install Node.js 20+

```bash
# Add Node.js 20 repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should be v20.x.x or higher
npm --version   # Should be 9.x.x or higher
```

### Step 3: Install PM2 and Nginx

```bash
# Install PM2 globally
sudo npm install -g pm2@latest

# Install Nginx
sudo apt install -y nginx

# Start and enable services
sudo systemctl start nginx
sudo systemctl enable nginx

# Setup PM2 startup script
pm2 startup
# Follow the displayed command to configure auto-start
```

### Step 4: Clone and Setup Application

```bash
# Clone the repository
git clone https://github.com/amirsalahshur/dev-resume.git
cd dev-resume

# Run automated service setup
sudo bash scripts/setup-service.sh
```

**Expected Output:**
```
[INFO] Starting portfolio service setup...
[SUCCESS] Prerequisites installed
[SUCCESS] Created user: portfolio
[SUCCESS] Directories created
[SUCCESS] Systemd service installed and enabled
[SUCCESS] Portfolio service setup completed!
```

**If service setup fails, try manual repair:**
```bash
# Repair broken systemd service installation
sudo bash scripts/setup-service.sh --repair

# Or manually fix systemd issues:
sudo systemctl daemon-reload
sleep 5
sudo systemctl enable portfolio
sudo systemctl list-unit-files | grep portfolio

# Verify service is recognized
sudo systemctl status portfolio
```

### Step 5: Deploy Application

```bash
# Copy application files
sudo cp -r * /var/www/portfolio/
sudo chown -R portfolio:portfolio /var/www/portfolio

# Switch to portfolio user and build
sudo -u portfolio bash -c "
  cd /var/www/portfolio
  npm ci --production=false
  npm run build
  npm run start:pm2
"

# Start systemd service
sudo systemctl start portfolio
sudo systemctl enable portfolio
```

### Step 6: Configure Nginx and SSL

```bash
# Copy nginx configuration
sudo cp /var/www/portfolio/nginx.conf /etc/nginx/sites-available/portfolio

# Edit with your domain (replace your-domain.com)
sudo nano /etc/nginx/sites-available/portfolio

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/

# Install SSL certificate
sudo apt install -y certbot python3-certbot-nginx

# Stop nginx temporarily for certificate generation
sudo systemctl stop nginx

# Generate SSL certificate (replace with your domain and email)
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@domain.com \
  --agree-tos \
  --non-interactive

# Start nginx and test
sudo systemctl start nginx
sudo nginx -t
sudo systemctl reload nginx
```

### Step 7: Verification

```bash
# Run comprehensive verification
sudo bash /var/www/portfolio/scripts/verify-deployment.sh

# Quick verification checks
sudo bash /var/www/portfolio/scripts/verify-deployment.sh --quick

# Test website connectivity
curl -I https://your-domain.com  # Should return 200 OK
curl -I http://your-domain.com   # Should redirect to HTTPS

# Verify individual components
sudo systemctl status portfolio  # Service should be active
sudo -u portfolio pm2 status     # PM2 processes should be online
sudo systemctl status nginx      # Nginx should be active
```

**Expected verification output:**
```
✓ PASS: Service is active/running
✓ PASS: Application responds on port 3000
✓ PASS: Health endpoint responds on port 3001
✓ PASS: Nginx is running
✓ PASS: SSL certificate is valid
```

---

## 🔄 GitHub Actions CI/CD Setup

### Required Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

```
PRODUCTION_HOST = your-server-ip-address
PRODUCTION_USER = portfolio
PRODUCTION_SSH_KEY = your-private-ssh-key
PRODUCTION_PORT = 22
```

### Required Repository Variables

```
ENABLE_PRODUCTION_DEPLOY = true
PRODUCTION_URL = https://your-domain.com
```

### Generate SSH Key for Deployment

```bash
# On your server, generate deployment key
sudo -u portfolio ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy_key -N ""

# Add public key to authorized_keys
sudo -u portfolio bash -c "cat ~/.ssh/github_deploy_key.pub >> ~/.ssh/authorized_keys"

# Display private key (add this to GitHub secrets)
sudo -u portfolio cat ~/.ssh/github_deploy_key
```

---

## 🛠️ Configuration Files

### Environment Variables

Create `/var/www/portfolio/.env`:

```bash
NODE_ENV=production
PORT=3000
HEALTH_CHECK_PORT=3001
LOG_LEVEL=info
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000
APP_NAME=portfolio
APP_VERSION=2.0.0
APP_USER=portfolio
APP_DIR=/var/www/portfolio
ENABLE_METRICS=true
METRICS_PORT=9090
```

### Nginx Configuration

Update these lines in `/etc/nginx/sites-available/portfolio`:

```nginx
# Replace with your actual domain
server_name your-domain.com www.your-domain.com;

# Replace with your actual domain
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
ssl_trusted_certificate /etc/letsencrypt/live/your-domain.com/chain.pem;
```

---

## 🔧 Common Commands

### Service Management
```bash
# Check service status
sudo systemctl status portfolio
sudo systemctl status nginx

# Restart services
sudo systemctl restart portfolio
sudo systemctl restart nginx

# View logs
sudo journalctl -u portfolio -f
sudo -u portfolio pm2 logs
```

### Application Management
```bash
# Deploy updates
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh

# Check PM2 status
sudo -u portfolio pm2 status

# Health check
curl http://localhost:3001/health
```

### SSL Certificate Management
```bash
# Check certificates
sudo certbot certificates

# Renew certificates
sudo certbot renew --dry-run
sudo certbot renew
```

---

## 🐛 Comprehensive Troubleshooting

### 🔧 Domain Validation Issues

**Issue: "Invalid domain format" error with subdomains**

```bash
# ERROR: Invalid domain format: info.amirsalahshur.xyz
```

**Solution:**
```bash
# Use --skip-domain-check flag for subdomains
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- info.amirsalahshur.xyz your-email@domain.com --skip-domain-check
```

**Supported domain formats:**
- `example.com` (standard domain)
- `subdomain.example.com` (single subdomain)
- `api.v2.example.com` (multi-level subdomain)
- `www.example.com` (www subdomain)

### 🔧 Systemd Service Issues

**Issue: "Systemd service not installed" error**

```bash
# ERROR: ✗ Systemd service not installed
```

**Solution Steps:**

1. **Manual systemd service repair:**
```bash
# Step 1: Reload systemd daemon
sudo systemctl daemon-reload
sleep 5

# Step 2: Re-enable the service
sudo systemctl enable portfolio

# Step 3: Verify service is recognized
sudo systemctl list-unit-files | grep portfolio

# Step 4: Check service status
sudo systemctl status portfolio
```

2. **Repair using the repair script:**
```bash
# Run the automated repair
sudo bash scripts/setup-service.sh --repair
```

3. **Manual service file recreation:**
```bash
# Copy service file manually
sudo cp portfolio.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/portfolio.service
sudo systemctl daemon-reload
sudo systemctl enable portfolio
```

**Verification commands:**
```bash
# Verify service installation
sudo systemctl list-unit-files | grep portfolio
sudo systemctl is-enabled portfolio  # Should return "enabled"
sudo systemctl status portfolio      # Should show service status
```

### 🔧 Application Won't Start

**Check diagnostics:**
```bash
# Check Node.js version
node --version  # Should be 20.x.x or higher

# Check PM2 processes
sudo -u portfolio pm2 list
sudo -u portfolio pm2 logs amir-portfolio --lines 50

# Check systemd service logs
sudo journalctl -u portfolio -n 50 --no-pager
```

**Fix steps:**
```bash
# Restart PM2 processes
sudo -u portfolio pm2 restart amir-portfolio

# Rebuild application
sudo -u portfolio bash -c "cd /var/www/portfolio && npm run build"

# Restart systemd service
sudo systemctl restart portfolio
```

### 🔧 SSL Certificate Problems

**Check certificate status:**
```bash
# List existing certificates
sudo certbot certificates

# Check certificate files
sudo ls -la /etc/letsencrypt/live/your-domain.com/

# Test nginx configuration
sudo nginx -t
```

**Fix certificate issues:**
```bash
# Remove problematic certificate
sudo certbot delete --cert-name your-domain.com

# Stop nginx temporarily
sudo systemctl stop nginx

# Generate new certificate (replace with your domain)
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@domain.com \
  --agree-tos \
  --non-interactive

# Start nginx and test
sudo systemctl start nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 🔧 Permission Issues

**Fix ownership and permissions:**
```bash
# Fix application directory ownership
sudo chown -R portfolio:portfolio /var/www/portfolio
sudo chown -R portfolio:portfolio /var/log/portfolio

# Fix directory permissions
sudo chmod 755 /var/www/portfolio
sudo chmod 755 /var/log/portfolio

# Fix PM2 directory permissions
sudo chown -R portfolio:portfolio /var/www/portfolio/.pm2
```

### 🔧 Network Connectivity Issues

**Check ports and connections:**
```bash
# Check if application ports are listening
sudo netstat -tulpn | grep 3000  # Main application
sudo netstat -tulpn | grep 3001  # Health check

# Test local connections
curl -I http://localhost:3000    # Should return 200 OK
curl -I http://localhost:3001/health  # Health endpoint

# Test external domain (after DNS propagation)
curl -I https://your-domain.com  # Should return 200 OK
```

**Fix network issues:**
```bash
# Check firewall status
sudo ufw status

# Ensure required ports are open
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow ssh

# Restart networking if needed
sudo systemctl restart networking
```

### 🔧 GitHub Actions Deployment Issues

**Check repository setup:**
- Verify you've **forked** the repository (don't use the original)
- Update repository URL in GitHub Actions secrets
- Configure your own domain in repository variables

**Required secrets configuration:**
```bash
# Generate SSH key for deployment
sudo -u portfolio ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy_key -N ""

# Add public key to authorized_keys
sudo -u portfolio bash -c "cat ~/.ssh/github_deploy_key.pub >> ~/.ssh/authorized_keys"

# Display private key (add this to GitHub secrets as PRODUCTION_SSH_KEY)
sudo -u portfolio cat ~/.ssh/github_deploy_key
```

**Test SSH connection:**
```bash
# Test SSH connection from your local machine
ssh -i /path/to/your/key portfolio@your-server-ip

# If connection fails, check:
sudo systemctl status ssh
sudo ufw status  # Ensure SSH port is allowed
```

---

## 📊 Performance Monitoring

### Setup System Monitoring
```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Setup PM2 monitoring
sudo -u portfolio pm2 install pm2-server-monit
sudo -u portfolio pm2 set pm2-server-monit:monitoring true
```

### Log Monitoring
```bash
# Real-time logs
sudo tail -f /var/log/portfolio/deploy.log
sudo -u portfolio pm2 logs --lines 20
sudo tail -f /var/log/nginx/portfolio_access.log
```

### Performance Testing
```bash
# Test response time
curl -o /dev/null -s -w "Total time: %{time_total}s\n" https://your-domain.com

# Test security headers
curl -I https://your-domain.com | grep -E "Strict-Transport-Security|X-Frame-Options"
```

---

## 🔒 Security Hardening

### Setup Fail2Ban
```bash
sudo apt install -y fail2ban

# Configure fail2ban for nginx
sudo bash -c 'cat > /etc/fail2ban/jail.local << EOF
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/portfolio_error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/portfolio_access.log
maxretry = 6
EOF'

sudo systemctl restart fail2ban
```

### Regular Updates
```bash
# Setup automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 📦 Backup and Recovery

### Manual Backup
```bash
# Create backup
sudo -u portfolio bash -c "
  BACKUP_DIR=\"/var/backups/portfolio/\$(date +%Y%m%d_%H%M%S)\"
  mkdir -p \"\$BACKUP_DIR\"
  cp -r /var/www/portfolio/dist \"\$BACKUP_DIR/\"
  cp /var/www/portfolio/package.json \"\$BACKUP_DIR/\"
  cp /var/www/portfolio/ecosystem.config.js \"\$BACKUP_DIR/\"
  echo \"Backup created: \$BACKUP_DIR\"
"
```

### Automated Backups
```bash
# Setup daily backups
sudo -u portfolio crontab -e
# Add: 0 2 * * * /var/www/portfolio/scripts/backup.sh
```

### Rollback
```bash
# Rollback to previous version
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh --rollback
```

---

## ✅ Complete Verification Checklist

After installation, systematically verify each component:

### 🌐 Domain and SSL
- [ ] **DNS Resolution**: `ping your-domain.com` resolves to server IP
- [ ] **Website loads**: `https://your-domain.com` loads successfully
- [ ] **HTTP redirect**: `http://your-domain.com` redirects to HTTPS
- [ ] **SSL certificate valid**: No browser warnings, certificate not expired
- [ ] **Subdomain support**: If using subdomain, it resolves correctly

### 🖥️ System Services
- [ ] **Systemd service active**: `sudo systemctl is-active portfolio` returns "active"
- [ ] **Service enabled**: `sudo systemctl is-enabled portfolio` returns "enabled"
- [ ] **Nginx running**: `sudo systemctl is-active nginx` returns "active"
- [ ] **No failed services**: `sudo systemctl --failed` shows no failed units

### 🔄 Application Processes
- [ ] **PM2 processes running**: `sudo -u portfolio pm2 status` shows online processes
- [ ] **Main app responds**: `curl http://localhost:3000/` returns 200 OK
- [ ] **Health endpoint**: `curl http://localhost:3001/health` returns health status
- [ ] **Process stability**: PM2 processes have been running without restarts

### 🔧 File System and Permissions
- [ ] **Application files exist**: `/var/www/portfolio/dist/index.html` exists
- [ ] **Correct ownership**: `stat /var/www/portfolio` shows `portfolio:portfolio`
- [ ] **Node modules installed**: `/var/www/portfolio/node_modules` contains dependencies
- [ ] **Build artifacts**: `/var/www/portfolio/dist` contains built application

### 🌐 Network and Connectivity
- [ ] **Ports listening**: `netstat -tulpn | grep :3000` and `:443` show listening
- [ ] **Firewall configured**: `sudo ufw status` shows ports 80, 443 allowed
- [ ] **External access**: Website accessible from external networks
- [ ] **Response time**: Website loads within 2-3 seconds

### 🔐 Security and Monitoring
- [ ] **SSL auto-renewal**: `sudo certbot certificates` shows valid certificate
- [ ] **Log rotation configured**: `/etc/logrotate.d/portfolio` exists
- [ ] **Fail2ban active**: `sudo systemctl is-active fail2ban` returns "active"
- [ ] **Automatic updates**: `sudo systemctl is-enabled unattended-upgrades`

### 🚀 CI/CD and Deployment
- [ ] **GitHub Actions configured**: Repository secrets and variables set
- [ ] **SSH key access**: GitHub Actions can SSH to server
- [ ] **Deploy scripts work**: `sudo -u portfolio bash scripts/deploy.sh --dry-run`
- [ ] **Rollback capability**: Backup and rollback procedures tested

### 📊 Monitoring and Logs
- [ ] **Logs being written**: `sudo journalctl -u portfolio -f` shows recent activity
- [ ] **PM2 logs accessible**: `sudo -u portfolio pm2 logs` shows application logs
- [ ] **Nginx logs**: `/var/log/nginx/portfolio_access.log` contains requests
- [ ] **Health monitoring**: Health check endpoint returns valid JSON

### 🧪 Automated Verification

Run the comprehensive verification script:
```bash
# Full verification suite
sudo bash /var/www/portfolio/scripts/verify-deployment.sh

# Quick essential checks
sudo bash /var/www/portfolio/scripts/verify-deployment.sh --quick

# Network connectivity only
sudo bash /var/www/portfolio/scripts/verify-deployment.sh --network
```

**Expected output for healthy installation:**
```
✓ PASS: Service is active/running
✓ PASS: Application responds on port 3000
✓ PASS: Health endpoint responds on port 3001
✓ PASS: Nginx is running
✓ PASS: SSL certificate is valid
✓ PASS: No recent errors in logs

=== DEPLOYMENT VERIFICATION SUMMARY ===
✓ Deployment verification PASSED
Checks passed: 25
Checks failed: 0
Warnings: 0
```

---

## 🎉 Deployment Complete!

Your portfolio is now live at `https://your-domain.com` with:

✅ **Zero-downtime deployments** with automatic rollback  
✅ **SSL/TLS encryption** with automatic renewal  
✅ **Process monitoring** with PM2 clustering  
✅ **Health checks** and monitoring endpoints  
✅ **Security hardening** with rate limiting and security headers  
✅ **CI/CD pipeline** with GitHub Actions  
✅ **Automated backups** and recovery procedures  
✅ **Comprehensive logging** and monitoring  

---

**Need Help?**
- Check the troubleshooting section above
- Review logs using the provided commands
- Ensure all prerequisites are met
- Verify domain DNS configuration

**Documentation Information:**
- **Version**: 2.0.0
- **Updated**: January 2025
- **Node.js**: 20.0.0+ Required
- **Compatibility**: Ubuntu 20.04 LTS, Ubuntu 22.04 LTS (recommended)
- **Subdomain Support**: Full support with `--skip-domain-check` flag
- **SSL**: Automatic Let's Encrypt certificates with auto-renewal
- **Deployment**: Zero-downtime with PM2 clustering and health checks

## 📚 Additional Resources

### 🔗 Useful Links
- **Original Repository**: [github.com/amirsalahshur/dev-resume](https://github.com/amirsalahshur/dev-resume)
- **Let's Encrypt Documentation**: [letsencrypt.org/docs](https://letsencrypt.org/docs/)
- **PM2 Documentation**: [pm2.keymetrics.io/docs](https://pm2.keymetrics.io/docs/)
- **Nginx Documentation**: [nginx.org/en/docs](http://nginx.org/en/docs/)

### 🎯 Best Practices
- **Regular Updates**: Keep system packages updated with `sudo apt update && sudo apt upgrade`
- **Monitor Logs**: Regularly check logs for errors or suspicious activity
- **SSL Renewal**: Verify SSL certificates auto-renew properly
- **Backup Strategy**: Implement regular automated backups
- **Security**: Keep firewall active and fail2ban monitoring enabled

### 📋 Maintenance Schedule
- **Daily**: Automated backups and security updates
- **Weekly**: Check SSL certificate status and log rotation
- **Monthly**: Review system performance and disk usage
- **Quarterly**: Update Node.js and other major dependencies
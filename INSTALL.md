# Complete Installation Guide

**Production-ready deployment guide for Amir Salahshur's Portfolio from fresh Ubuntu server to live website**

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- **CPU**: 1 vCPU (2+ recommended for production)
- **RAM**: 2GB (4GB+ recommended)
- **Storage**: 20GB free space (50GB+ recommended)
- **Network**: Public IP address with domain name

### Software Requirements
- **Node.js**: 20.0.0 or higher
- **npm**: 9.0.0 or higher
- **PM2**: Latest version
- **Nginx**: Latest version
- **Git**: Latest version

### Domain Requirements
- Domain name pointing to server IP
- DNS A records configured
- Optional: WWW subdomain setup

---

## 🚀 Quick Installation (One Command)

For a complete automated installation on a fresh Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com
```

**What this does:**
1. Installs all prerequisites (Node.js 20+, PM2, Nginx)
2. Creates portfolio user and directories
3. Clones the repository
4. Builds the application
5. Configures systemd service
6. Sets up Nginx with SSL
7. Starts the application

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

# Test website
curl -I https://your-domain.com  # Should return 200 OK
curl -I http://your-domain.com   # Should redirect to HTTPS
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

## 🐛 Troubleshooting

### Issue: Application Won't Start

**Check:**
```bash
sudo -u portfolio pm2 logs amir-portfolio --lines 50
sudo journalctl -u portfolio -n 50
node --version  # Should be 20+
```

**Fix:**
```bash
sudo -u portfolio pm2 restart amir-portfolio
sudo -u portfolio bash -c "cd /var/www/portfolio && npm run build"
```

### Issue: SSL Certificate Problems

**Check:**
```bash
sudo ls -la /etc/letsencrypt/live/your-domain.com/
sudo nginx -t
```

**Fix:**
```bash
sudo certbot delete --cert-name your-domain.com
sudo systemctl stop nginx
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com
sudo systemctl start nginx
```

### Issue: Permission Denied

**Fix:**
```bash
sudo chown -R portfolio:portfolio /var/www/portfolio
sudo chown -R portfolio:portfolio /var/log/portfolio
sudo chmod 755 /var/www/portfolio
```

### Issue: GitHub Actions Failing

**Check:**
- Verify all secrets are configured in GitHub
- Test SSH connection: `ssh -i /path/to/key portfolio@your-server`
- Check deploy key permissions

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

## ✅ Verification Checklist

After installation, verify:

- [ ] Website loads at https://your-domain.com
- [ ] HTTP redirects to HTTPS
- [ ] SSL certificate is valid
- [ ] PM2 processes are running
- [ ] Health check endpoint responds
- [ ] Systemd service is active
- [ ] GitHub Actions deploy successfully
- [ ] Logs are being written
- [ ] Automatic certificate renewal is configured

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

**Version**: 2.0.0  
**Updated**: January 2025  
**Node.js**: 20+ Required  
**Compatibility**: Ubuntu 20.04+, Ubuntu 22.04+
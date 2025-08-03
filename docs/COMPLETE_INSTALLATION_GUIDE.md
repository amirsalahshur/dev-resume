# Complete Portfolio Installation Guide

**A comprehensive, step-by-step guide to deploy Amir Salahshur's portfolio from fresh Ubuntu server to production-ready website**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [System Requirements](#system-requirements)
3. [Prerequisites & Server Preparation](#prerequisites--server-preparation)
4. [Application Installation](#application-installation)
5. [Service Configuration](#service-configuration)
6. [Web Server Setup](#web-server-setup)
7. [SSL Certificate Setup](#ssl-certificate-setup)
8. [Deployment Configuration](#deployment-configuration)
9. [Testing & Verification](#testing--verification)
10. [GitHub Actions CI/CD Setup](#github-actions-cicd-setup)
11. [Post-Installation Tasks](#post-installation-tasks)
12. [Troubleshooting](#troubleshooting)
13. [Configuration Reference](#configuration-reference)

---

## 🎯 Project Overview

### What is This Project?

This is a **modern, production-ready portfolio website** for Amir Salahshur, a Full Stack Developer & DevOps Engineer. The project showcases advanced web development practices and enterprise-grade deployment strategies.

### Key Features

- **🎨 Modern Frontend**: Responsive design with interactive matrix background effect
- **⚡ Performance Optimized**: Built with Vite, optimized assets, and CDN-ready
- **🔒 Security Focused**: HTTPS, security headers, rate limiting, and CSP
- **📱 Responsive Design**: Mobile-first approach with progressive enhancement
- **♿ Accessibility**: WCAG compliant with screen reader support
- **🚀 Zero-Downtime Deployments**: Rolling updates with health checks
- **📊 Monitoring**: Health checks, metrics, and logging
- **🐳 Docker Ready**: Container support with multi-stage builds
- **🔄 CI/CD Pipeline**: Automated testing and deployment with GitHub Actions

### Technologies Used

#### Frontend Stack
- **HTML5**: Semantic markup with accessibility features
- **CSS3**: Modern CSS with Grid, Flexbox, and custom properties
- **JavaScript (ES6+)**: Modular architecture with Canvas API effects
- **Vite**: Build tool for fast development and optimized production builds

#### Backend & Infrastructure
- **Node.js 18+**: Runtime environment
- **PM2**: Process management with clustering and health monitoring
- **Nginx**: Reverse proxy with SSL termination and security features
- **Let's Encrypt**: Automated SSL certificate management
- **systemd**: Service management and auto-restart capabilities

#### DevOps & Deployment
- **Docker**: Containerization with multi-stage builds
- **Docker Compose**: Multi-service orchestration
- **GitHub Actions**: CI/CD pipeline with automated testing
- **Ubuntu 20.04+**: Target deployment platform

#### Monitoring & Observability
- **Health Check Service**: Custom Node.js health monitoring
- **Prometheus**: Metrics collection (optional)
- **Grafana**: Monitoring dashboards (optional)
- **Log Rotation**: Automated log management

### Deployment Capabilities

- **Zero-Downtime Updates**: Rolling deployments with automatic rollback
- **Health Monitoring**: Application and system health checks
- **SSL/TLS**: Automatic certificate provisioning and renewal
- **Load Balancing**: PM2 cluster mode for high availability
- **Security Headers**: HSTS, CSP, CORS, and other security measures
- **Rate Limiting**: Protection against abuse and DDoS
- **Backup & Recovery**: Automated backups with rollback capabilities
- **CI/CD Integration**: Automated deployment from GitHub

---

## 🖥️ System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04 LTS or later (Debian-based distributions)
- **CPU**: 1 vCPU (2+ recommended for production)
- **RAM**: 1GB (2GB+ recommended)
- **Storage**: 10GB free space (20GB+ recommended)
- **Network**: Public IP address with domain name

### Recommended Production Setup
- **CPU**: 2+ vCPUs
- **RAM**: 4GB+
- **Storage**: 50GB+ SSD
- **Network**: Static IP with CDN integration

### Domain Requirements
- Domain name pointing to server IP
- DNS A records configured
- Optional: WWW subdomain setup

---

## 🔧 Prerequisites & Server Preparation

### Step 1: Initial Server Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install build tools
sudo apt install -y build-essential

# Configure timezone (replace with your timezone)
sudo timedatectl set-timezone UTC
```

**Expected Output:**
```
Reading package lists... Done
Building dependency tree... Done
Get:1 http://archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
...
Setting up build-essential (12.8ubuntu1.1) ...
```

### Step 2: Create Non-Root User (if needed)

```bash
# Create deployment user
sudo adduser deploy
sudo usermod -aG sudo deploy

# Switch to deployment user
su - deploy
```

### Step 3: Configure SSH Key Authentication

```bash
# Generate SSH key (if not already done)
ssh-keygen -t rsa -b 4096 -C "your-email@domain.com"

# Add public key to authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Add your public key to ~/.ssh/authorized_keys
```

### Step 4: Configure Firewall

```bash
# Install and configure UFW firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Verify firewall status
sudo ufw status
```

**Expected Output:**
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

---

## 📦 Application Installation

### Step 5: Install Node.js 18+

```bash
# Add Node.js 18 repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

**Expected Output:**
```
v18.19.0
9.2.0
```

### Step 6: Install PM2 Process Manager

```bash
# Install PM2 globally
sudo npm install -g pm2@latest

# Verify PM2 installation
pm2 --version

# Setup PM2 startup script
pm2 startup
# Follow the displayed command to configure auto-start
```

**Expected Output:**
```
5.3.0
[PM2] Init System found: systemd
[PM2] To setup the Startup Script, copy/paste the following command:
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u deploy --hp /home/deploy
```

### Step 7: Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify Nginx is running
sudo systemctl status nginx
```

**Expected Output:**
```
● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since [date]
```

### Step 8: Clone the Project

```bash
# Clone the repository
git clone https://github.com/amirsalahshur/dev-resume.git
cd dev-resume

# Verify project structure
ls -la
```

**Expected Output:**
```
total 48
drwxrwxr-x  8 deploy deploy 4096 Jan 15 10:00 .
drwxr-xr-x  3 deploy deploy 4096 Jan 15 10:00 ..
-rw-rw-r--  1 deploy deploy 1234 Jan 15 10:00 Dockerfile
-rw-rw-r--  1 deploy deploy 2345 Jan 15 10:00 README.md
drwxrwxr-x  2 deploy deploy 4096 Jan 15 10:00 docs
-rw-rw-r--  1 deploy deploy 1567 Jan 15 10:00 ecosystem.config.js
-rw-rw-r--  1 deploy deploy 3456 Jan 15 10:00 nginx.conf
-rw-rw-r--  1 deploy deploy 2890 Jan 15 10:00 package.json
-rw-rw-r--  1 deploy deploy 1234 Jan 15 10:00 portfolio.service
drwxrwxr-x  3 deploy deploy 4096 Jan 15 10:00 scripts
drwxrwxr-x  5 deploy deploy 4096 Jan 15 10:00 src
```

---

## ⚙️ Service Configuration

### Step 9: Run Automated Service Setup

```bash
# Navigate to project directory
cd /home/deploy/dev-resume

# Run the automated setup script
sudo bash scripts/setup-service.sh
```

**What this script does:**
1. Creates `portfolio` system user and group
2. Creates application directories (`/var/www/portfolio`, `/var/log/portfolio`)
3. Installs the systemd service
4. Configures log rotation
5. Sets up firewall rules
6. Configures sudo permissions for the portfolio user

**Expected Output:**
```
[2024-01-15 10:00:00] INFO: Starting portfolio service setup...
[2024-01-15 10:00:01] SUCCESS: Prerequisites installed
[2024-01-15 10:00:02] SUCCESS: Created user: portfolio
[2024-01-15 10:00:03] SUCCESS: Directories created
[2024-01-15 10:00:04] INFO: Using service file: /home/deploy/dev-resume/portfolio.service
[2024-01-15 10:00:05] SUCCESS: Systemd service installed and enabled
[2024-01-15 10:00:06] SUCCESS: ✓ User portfolio exists
[2024-01-15 10:00:07] SUCCESS: ✓ Application directory configured correctly
[2024-01-15 10:00:08] SUCCESS: ✓ Systemd service installed
[2024-01-15 10:00:09] SUCCESS: Portfolio service setup completed!
```

### Step 10: Verify Service Installation

```bash
# Check systemd service status
sudo systemctl status portfolio

# Verify portfolio user was created
getent passwd portfolio

# Check application directory
ls -la /var/www/portfolio
```

### Step 11: Copy Application Files

```bash
# Copy project files to application directory
sudo cp -r /home/deploy/dev-resume/* /var/www/portfolio/
sudo chown -R portfolio:portfolio /var/www/portfolio

# Switch to portfolio user for application setup
sudo su - portfolio
cd /var/www/portfolio
```

---

## 🏗️ Application Installation (as portfolio user)

### Step 12: Install Dependencies and Build

```bash
# Install project dependencies
npm ci --production=false

# Build the application for production
npm run build

# Verify build was successful
ls -la dist/
cat dist/index.html | head -5
```

**Expected Output:**
```
dist/
├── assets/
│   ├── css/
│   ├── images/
│   └── js/
├── index.html
└── robots.txt

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Amir Salahshur - Portfolio</title>
```

### Step 13: Configure Environment

```bash
# Create production environment file
cat > .env << 'EOF'
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
EOF

# Set proper permissions
chmod 640 .env
```

### Step 14: Start Application with PM2

```bash
# Start the application using PM2
npm run start:pm2

# Check PM2 status
pm2 status

# Save PM2 configuration
pm2 save

# Test health check endpoint
curl http://localhost:3001/health
```

**Expected Output:**
```
┌─────┬──────────────────────┬─────────────┬─────────┬─────────┬──────────┬────────┬──────┬───────────┬──────────┬──────────┬──────────┬──────────┐
│ id  │ name                 │ namespace   │ version │ mode    │ pid      │ uptime │ ↺    │ status    │ cpu      │ mem      │ user     │ watching │
├─────┼──────────────────────┼─────────────┼─────────┼─────────┼──────────┼────────┼──────┼───────────┼──────────┼──────────┼──────────┼──────────┤
│ 0   │ amir-portfolio       │ default     │ 2.0.0   │ cluster │ 12345    │ 2s     │ 0    │ online    │ 0%       │ 45.2mb   │ portfolio│ disabled │
│ 1   │ portfolio-health-che │ default     │ 2.0.0   │ fork    │ 12346    │ 2s     │ 0    │ online    │ 0%       │ 25.1mb   │ portfolio│ disabled │
└─────┴──────────────────────┴─────────────┴─────────┴─────────┴──────────┴────────┴──────┴───────────┴──────────┴──────────┴──────────┴──────────┘

{
  "status": "healthy",
  "timestamp": "2024-01-15T10:00:00.000Z",
  "uptime": 5,
  "checks": {...}
}
```

### Step 15: Enable Systemd Service

```bash
# Exit portfolio user session
exit

# Start and enable the portfolio systemd service
sudo systemctl start portfolio
sudo systemctl enable portfolio

# Check service status
sudo systemctl status portfolio
```

---

## 🌐 Web Server Setup

### Step 16: Configure Domain Name

**IMPORTANT**: Before proceeding, ensure your domain's DNS A record points to your server's IP address.

```bash
# Check DNS resolution
nslookup your-domain.com
dig your-domain.com A
```

### Step 17: Configure Nginx

```bash
# Copy nginx configuration to sites-available
sudo cp /var/www/portfolio/nginx.conf /etc/nginx/sites-available/portfolio

# Edit the configuration with your domain
sudo nano /etc/nginx/sites-available/portfolio
```

**Update these lines in the nginx configuration:**
```nginx
# Replace these lines:
server_name your-domain.com www.your-domain.com;
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
ssl_trusted_certificate /etc/letsencrypt/live/your-domain.com/chain.pem;

# With your actual domain:
server_name mydomain.com www.mydomain.com;
ssl_certificate /etc/letsencrypt/live/mydomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/mydomain.com/privkey.pem;
ssl_trusted_certificate /etc/letsencrypt/live/mydomain.com/chain.pem;
```

### Step 18: Enable Nginx Site

```bash
# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable portfolio site
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/

# Test nginx configuration (this will fail initially due to missing SSL certificates)
sudo nginx -t

# Start nginx anyway (for SSL certificate generation)
sudo systemctl restart nginx
```

**Expected Output (with SSL certificate error):**
```
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/mydomain.com/fullchain.pem": BIO_new_file() failed
nginx: configuration file /etc/nginx/nginx.conf test failed
```

This is expected - we'll fix this in the next section by generating SSL certificates.

---

## 🔐 SSL Certificate Setup

### Step 19: Install Certbot

```bash
# Install Certbot and Nginx plugin
sudo apt install -y certbot python3-certbot-nginx

# Verify Certbot installation
certbot --version
```

### Step 20: Generate SSL Certificates

```bash
# Stop nginx temporarily for initial certificate generation
sudo systemctl stop nginx

# Generate SSL certificate using standalone mode
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@domain.com \
  --agree-tos \
  --non-interactive

# Start nginx after certificate generation
sudo systemctl start nginx

# Test nginx configuration (should pass now)
sudo nginx -t

# Reload nginx with SSL configuration
sudo systemctl reload nginx
```

**Expected Output:**
```
Requesting a certificate for your-domain.com and www.your-domain.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/your-domain.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/your-domain.com/privkey.pem
This certificate expires on 2024-04-15.
```

### Step 21: Setup Automatic Certificate Renewal

```bash
# Test certificate renewal
sudo certbot renew --dry-run

# The renewal cron job is automatically installed by certbot
# Verify it exists
sudo crontab -l | grep certbot
```

**Expected Output:**
```
0 12 * * * /usr/bin/certbot renew --quiet
```

---

## 🚀 Deployment Configuration

### Step 22: Test Zero-Downtime Deployment

```bash
# Test the deployment script as portfolio user
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh --status

# Run a full deployment test
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh
```

**Expected Output:**
```
[2024-01-15 10:15:00] INFO: Starting zero-downtime deployment of amir-portfolio
[2024-01-15 10:15:01] SUCCESS: Prerequisites check passed
[2024-01-15 10:15:02] SUCCESS: Backup created at /var/backups/portfolio/20240115_101502
[2024-01-15 10:15:10] SUCCESS: Dependencies installed successfully
[2024-01-15 10:15:15] SUCCESS: Application built successfully
[2024-01-15 10:15:16] SUCCESS: PM2 deployment completed
[2024-01-15 10:15:17] SUCCESS: Nginx reloaded successfully
[2024-01-15 10:15:20] SUCCESS: Post-deployment checks passed
[2024-01-15 10:15:21] SUCCESS: Zero-downtime deployment completed successfully!
```

### Step 23: Configure Git for Future Deployments

```bash
# Configure git for the portfolio user
sudo -u portfolio git config --global user.name "Portfolio Deploy"
sudo -u portfolio git config --global user.email "deploy@your-domain.com"

# Set up remote repository access (if using private repo)
sudo -u portfolio ssh-keygen -t rsa -b 4096 -C "portfolio@your-domain.com"
# Add the public key to your GitHub account
```

---

## ✅ Testing & Verification

### Step 24: Comprehensive Verification

```bash
# Run the comprehensive verification script
sudo bash /var/www/portfolio/scripts/verify-deployment.sh
```

**Expected Output:**
```
[2024-01-15 10:20:00] INFO: Starting deployment verification...

[2024-01-15 10:20:01] SUCCESS: ✓ node is installed
[2024-01-15 10:20:01] SUCCESS: ✓ npm is installed
[2024-01-15 10:20:01] SUCCESS: ✓ pm2 is installed
[2024-01-15 10:20:01] SUCCESS: ✓ curl is installed
[2024-01-15 10:20:01] SUCCESS: ✓ systemctl is installed
[2024-01-15 10:20:02] SUCCESS: Node.js version: v18.19.0
[2024-01-15 10:20:02] SUCCESS: PM2 version: 5.3.0

[2024-01-15 10:20:03] SUCCESS: ✓ User portfolio exists
[2024-01-15 10:20:03] SUCCESS: ✓ Application directory configured correctly
[2024-01-15 10:20:04] SUCCESS: ✓ Service file copied to systemd
[2024-01-15 10:20:04] SUCCESS: ✓ Systemd service installed
[2024-01-15 10:20:04] SUCCESS: ✓ Service is enabled
[2024-01-15 10:20:05] SUCCESS: ✓ PM2 is accessible for service user
[2024-01-15 10:20:05] SUCCESS: ✓ Portfolio process is online in PM2
[2024-01-15 10:20:06] SUCCESS: ✓ Application port 3000 is listening
[2024-01-15 10:20:06] SUCCESS: ✓ Health check port 3001 is listening
[2024-01-15 10:20:07] SUCCESS: ✓ Application responds on port 3000
[2024-01-15 10:20:07] SUCCESS: ✓ Health endpoint responds on port 3001

[2024-01-15 10:20:08] INFO: === DEPLOYMENT VERIFICATION SUMMARY ===
[2024-01-15 10:20:08] SUCCESS: ✓ Deployment verification PASSED
[2024-01-15 10:20:08] INFO: Checks passed: 25
[2024-01-15 10:20:08] INFO: Checks failed: 0
[2024-01-15 10:20:08] INFO: Warnings: 0
[2024-01-15 10:20:08] INFO: Total checks: 25
[2024-01-15 10:20:08] INFO: Deployment is fully operational!
```

### Step 25: Test Website Access

```bash
# Test HTTP redirect to HTTPS
curl -I http://your-domain.com
# Should return 301 redirect

# Test HTTPS access
curl -I https://your-domain.com
# Should return 200 OK

# Test health endpoints
curl https://your-domain.com/health
# Should return health status (from localhost only)

# Test SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com < /dev/null | grep -E 'Verify return code|subject='
```

**Expected Outputs:**
```bash
# HTTP redirect test:
HTTP/1.1 301 Moved Permanently
Location: https://your-domain.com/

# HTTPS access test:
HTTP/2 200
content-type: text/html
```

### Step 26: Performance and Security Testing

```bash
# Test page load time
curl -o /dev/null -s -w "Total time: %{time_total}s\n" https://your-domain.com

# Test security headers
curl -I https://your-domain.com | grep -E "Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options"

# Test SSL rating (optional, requires external tool)
# Use SSL Labs (https://www.ssllabs.com/ssltest/) for comprehensive SSL testing
```

---

## 🔄 GitHub Actions CI/CD Setup

### Step 27: Configure GitHub Repository Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

#### Required Secrets:
```
PRODUCTION_HOST = your-server-ip-address
PRODUCTION_USER = portfolio
PRODUCTION_SSH_KEY = your-private-ssh-key
PRODUCTION_PORT = 22
```

#### Required Variables:
```
ENABLE_PRODUCTION_DEPLOY = true
PRODUCTION_URL = https://your-domain.com
```

#### Optional Secrets:
```
STAGING_HOST = your-staging-server-ip
STAGING_USER = portfolio
STAGING_SSH_KEY = your-staging-ssh-key
STAGING_PORT = 22
SLACK_WEBHOOK = your-slack-webhook-url
```

#### Optional Variables:
```
ENABLE_STAGING_DEPLOY = false
STAGING_URL = https://staging.your-domain.com
```

### Step 28: Generate SSH Key for GitHub Actions

```bash
# On your deployment server, generate a deployment key
sudo -u portfolio ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy_key -N ""

# Display the public key (add this to your server's authorized_keys)
sudo -u portfolio cat /home/portfolio/.ssh/github_deploy_key.pub >> /home/portfolio/.ssh/authorized_keys

# Display the private key (add this to GitHub secrets as PRODUCTION_SSH_KEY)
sudo -u portfolio cat /home/portfolio/.ssh/github_deploy_key
```

### Step 29: Test GitHub Actions

```bash
# Push a change to trigger deployment
git add .
git commit -m "Test automated deployment"
git push origin main

# Monitor the deployment in GitHub Actions tab
# The workflow will:
# 1. Run tests and build
# 2. Create Docker image
# 3. Deploy to production (if configured)
# 4. Run health checks
# 5. Send notifications (if configured)
```

---

## 📋 Post-Installation Tasks

### Step 30: Setup Monitoring and Logging

```bash
# Setup log rotation verification
sudo logrotate -d /etc/logrotate.d/portfolio

# Monitor logs in real-time
sudo tail -f /var/log/portfolio/deploy.log &
sudo -u portfolio pm2 logs --lines 20

# Setup system monitoring (optional)
sudo apt install -y htop iotop nethogs
```

### Step 31: Create Backup Strategy

```bash
# Create backup script
sudo -u portfolio cat > /var/www/portfolio/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/portfolio/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /var/www/portfolio/dist "$BACKUP_DIR/"
cp /var/www/portfolio/package.json "$BACKUP_DIR/"
cp /var/www/portfolio/ecosystem.config.js "$BACKUP_DIR/"
echo "Backup created: $BACKUP_DIR"
EOF

sudo chmod +x /var/www/portfolio/scripts/backup.sh

# Test backup
sudo -u portfolio /var/www/portfolio/scripts/backup.sh

# Setup daily backups (optional)
sudo -u portfolio crontab -e
# Add: 0 2 * * * /var/www/portfolio/scripts/backup.sh
```

### Step 32: Performance Optimization

```bash
# Enable nginx compression modules (if not already enabled)
sudo nginx -V 2>&1 | grep -o with-http_gzip_static_module
sudo nginx -V 2>&1 | grep -o with-http_v2_module

# Optimize PM2 for production
sudo -u portfolio pm2 install pm2-server-monit
sudo -u portfolio pm2 set pm2-server-monit:monitoring true

# Setup performance monitoring
sudo -u portfolio pm2 monit
```

### Step 33: Security Hardening

```bash
# Setup fail2ban for additional security
sudo apt install -y fail2ban

# Configure fail2ban for nginx
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/portfolio_error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/portfolio_access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/portfolio_access.log
maxretry = 2
EOF

sudo systemctl restart fail2ban

# Verify fail2ban is running
sudo fail2ban-client status
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Application Won't Start

**Symptoms:**
```
pm2 status shows "errored" or "stopped"
```

**Diagnosis:**
```bash
# Check PM2 logs
sudo -u portfolio pm2 logs amir-portfolio --lines 50

# Check systemd logs
sudo journalctl -u portfolio -n 50

# Check Node.js version
node --version
```

**Solutions:**
```bash
# Restart PM2 process
sudo -u portfolio pm2 restart amir-portfolio

# Rebuild application
sudo -u portfolio bash -c "cd /var/www/portfolio && npm run build"

# Check for missing dependencies
sudo -u portfolio bash -c "cd /var/www/portfolio && npm ci"
```

#### Issue 2: SSL Certificate Problems

**Symptoms:**
```
nginx: [emerg] cannot load certificate
Browser shows "Not Secure" warning
```

**Diagnosis:**
```bash
# Check certificate files
sudo ls -la /etc/letsencrypt/live/your-domain.com/

# Test certificate
sudo openssl x509 -in /etc/letsencrypt/live/your-domain.com/fullchain.pem -text -noout

# Check certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

**Solutions:**
```bash
# Regenerate certificate
sudo certbot delete --cert-name your-domain.com
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Test renewal
sudo certbot renew --dry-run
```

#### Issue 3: Nginx Configuration Errors

**Symptoms:**
```
nginx: configuration file test failed
502 Bad Gateway errors
```

**Diagnosis:**
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx error logs
sudo tail -f /var/log/nginx/portfolio_error.log

# Check if upstream is running
curl -I http://localhost:3000
```

**Solutions:**
```bash
# Fix nginx configuration
sudo nano /etc/nginx/sites-available/portfolio

# Restart nginx
sudo systemctl restart nginx

# Check application is running
sudo -u portfolio pm2 status
```

#### Issue 4: Permission Denied Errors

**Symptoms:**
```
EACCES: permission denied
Cannot write to log files
```

**Diagnosis:**
```bash
# Check file ownership
ls -la /var/www/portfolio/
ls -la /var/log/portfolio/

# Check current user
whoami
```

**Solutions:**
```bash
# Fix ownership
sudo chown -R portfolio:portfolio /var/www/portfolio
sudo chown -R portfolio:portfolio /var/log/portfolio

# Fix permissions
sudo chmod 755 /var/www/portfolio
sudo chmod 755 /var/log/portfolio
```

#### Issue 5: GitHub Actions Deployment Failures

**Symptoms:**
```
GitHub Actions show "Some checks were not successful"
SSH connection failures in CI/CD
```

**Diagnosis:**
```bash
# Check SSH key
sudo -u portfolio ssh -T git@github.com

# Verify secrets in GitHub
# Check repository Settings → Secrets and variables → Actions
```

**Solutions:**
```bash
# Regenerate SSH keys
sudo -u portfolio ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy_key

# Update GitHub secrets with new private key
# Ensure server can be reached from GitHub runners
```

### Debug Commands

```bash
# System status
sudo systemctl status portfolio nginx
sudo ufw status
free -h
df -h

# Application status
sudo -u portfolio pm2 status
sudo -u portfolio pm2 monit
curl -I http://localhost:3000
curl -I http://localhost:3001/health

# Logs
sudo tail -f /var/log/portfolio/deploy.log
sudo -u portfolio pm2 logs --lines 50
sudo journalctl -u portfolio -f
sudo tail -f /var/log/nginx/portfolio_error.log

# Network
sudo netstat -tulpn | grep -E ':(80|443|3000|3001)'
sudo ss -tulpn | grep -E ':(80|443|3000|3001)'

# SSL/TLS
openssl s_client -connect your-domain.com:443 -servername your-domain.com
sudo certbot certificates
```

---

## 📚 Configuration Reference

### Environment Variables

Create `/var/www/portfolio/.env`:

```bash
# Application Configuration
NODE_ENV=production
PORT=3000
HEALTH_CHECK_PORT=3001
LOG_LEVEL=info

# Health Check Configuration
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000

# Application Metadata
APP_NAME=portfolio
APP_VERSION=2.0.0
APP_USER=portfolio
APP_DIR=/var/www/portfolio

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090

# Security (optional)
RATE_LIMIT_MAX=100
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Email Configuration (if contact form is implemented)
SMTP_HOST=smtp.your-email-provider.com
SMTP_PORT=587
SMTP_USER=your-email@domain.com
SMTP_PASS=your-app-password

# Analytics (optional)
GA_TRACKING_ID=your-google-analytics-id
```

### PM2 Configuration (ecosystem.config.js)

```javascript
module.exports = {
  apps: [
    {
      name: 'amir-portfolio',
      script: 'npm',
      args: 'run serve',
      instances: 'max',
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'portfolio-health-check',
      script: './scripts/health-check.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        HEALTH_CHECK_PORT: 3001,
        MAIN_APP_PORT: 3000
      }
    }
  ]
};
```

### Nginx Configuration Template

Key sections to customize in `/etc/nginx/sites-available/portfolio`:

```nginx
# Update server_name
server_name your-domain.com www.your-domain.com;

# Update SSL certificate paths
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

# Update document root if needed
root /var/www/portfolio/dist;

# Custom error pages (optional)
error_page 404 /404.html;
error_page 500 502 503 504 /50x.html;
```

### Systemd Service Configuration

`/etc/systemd/system/portfolio.service`:

```ini
[Unit]
Description=Portfolio Website - Amir Salahshur
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=forking
User=portfolio
Group=portfolio
WorkingDirectory=/var/www/portfolio
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=HEALTH_CHECK_PORT=3001
Environment=PM2_HOME=/var/www/portfolio/.pm2

ExecStart=/usr/bin/pm2 start ecosystem.config.js --env production
ExecReload=/usr/bin/pm2 reload ecosystem.config.js --env production
ExecStop=/usr/bin/pm2 kill

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Useful Commands Quick Reference

```bash
# Service Management
sudo systemctl {start|stop|restart|status} portfolio
sudo systemctl {start|stop|restart|status} nginx

# PM2 Management
sudo -u portfolio pm2 {start|stop|restart|reload|status}
sudo -u portfolio pm2 logs [app-name]
sudo -u portfolio pm2 monit

# Deployment
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh
sudo -u portfolio bash /var/www/portfolio/scripts/deploy.sh --rollback

# SSL Certificates
sudo certbot certificates
sudo certbot renew
sudo certbot renew --dry-run

# Logs
sudo journalctl -u portfolio -f
sudo -u portfolio pm2 logs
sudo tail -f /var/log/nginx/portfolio_error.log

# System Monitoring
htop
sudo netstat -tulpn
sudo ss -tulpn
df -h
free -h

# Health Checks
curl http://localhost:3001/health
curl https://your-domain.com
bash /var/www/portfolio/scripts/verify-deployment.sh
```

---

## 🎉 Conclusion

You now have a fully deployed, production-ready portfolio website with:

✅ **Zero-downtime deployments** with automatic rollback  
✅ **SSL/TLS encryption** with automatic renewal  
✅ **Process monitoring** with PM2 clustering  
✅ **Health checks** and monitoring endpoints  
✅ **Security hardening** with rate limiting and security headers  
✅ **CI/CD pipeline** with GitHub Actions  
✅ **Automated backups** and recovery procedures  
✅ **Comprehensive logging** and monitoring  

Your portfolio is now accessible at `https://your-domain.com` and ready for production use!

For ongoing maintenance, refer to the troubleshooting section and use the provided commands for monitoring and management.

---

**Need Help?**
- Check the [troubleshooting section](#troubleshooting) above
- Review logs using the provided commands
- Ensure all prerequisites are met
- Verify domain DNS configuration
- Test each step individually if issues occur

**Last Updated:** January 2024  
**Version:** 2.0.0  
**Compatibility:** Ubuntu 20.04+, Node.js 18+
# Manual Deployment Guide

This guide provides step-by-step instructions for manually deploying the portfolio application when the automated setup script fails.

## Prerequisites

- Ubuntu/Debian server with root access
- Node.js 18+ installed
- Git installed

## 1. Immediate Fix for Current Service Installation

### Problem: "Systemd service not installed" error

The setup script looks for `portfolio.service` in the current directory, but when running from `/root/dev-resume/scripts/`, it can't find the service file in the project root.

**Solution**: Run the setup script from the project root:

```bash
cd /root/dev-resume
sudo bash scripts/setup-service.sh
```

## 2. Manual Service Installation Steps

If the automated script continues to fail, follow these manual steps:

### Step 1: Create System User and Directories

```bash
# Create portfolio user and group
sudo groupadd --system portfolio
sudo useradd --system \
    --gid portfolio \
    --create-home \
    --home-dir /var/www/portfolio \
    --shell /bin/bash \
    --comment "Portfolio application user" \
    portfolio

# Create directories
sudo mkdir -p /var/www/portfolio
sudo mkdir -p /var/log/portfolio
sudo mkdir -p /var/backups/portfolio

# Set permissions
sudo chown -R portfolio:portfolio /var/www/portfolio
sudo chown -R portfolio:portfolio /var/log/portfolio
sudo chown -R portfolio:portfolio /var/backups/portfolio
sudo chmod 755 /var/www/portfolio /var/log/portfolio /var/backups/portfolio
```

### Step 2: Install Dependencies

```bash
# Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2@latest

# Install other dependencies
sudo apt-get update
sudo apt-get install -y nginx curl wget git sudo logrotate
```

### Step 3: Install Systemd Service

```bash
# Copy service file from project to systemd
sudo cp /root/dev-resume/portfolio.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/portfolio.service

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable portfolio

# Verify service is installed
sudo systemctl list-unit-files | grep portfolio
```

### Step 4: Copy Application Code

```bash
# Copy project files to application directory
sudo cp -r /root/dev-resume/* /var/www/portfolio/
sudo chown -R portfolio:portfolio /var/www/portfolio

# Create PM2 directories
sudo mkdir -p /var/www/portfolio/.pm2
sudo chown portfolio:portfolio /var/www/portfolio/.pm2
```

### Step 5: Install Application Dependencies

```bash
# Switch to portfolio user and install dependencies
sudo -u portfolio bash -c "cd /var/www/portfolio && npm install"

# Build the application
sudo -u portfolio bash -c "cd /var/www/portfolio && npm run build"
```

### Step 6: Create Environment File

```bash
sudo -u portfolio tee /var/www/portfolio/.env << EOF
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
```

### Step 7: Start the Service

```bash
# Start the portfolio service
sudo systemctl start portfolio

# Check service status
sudo systemctl status portfolio

# Enable service to start on boot
sudo systemctl enable portfolio
```

## 3. Service Verification Commands

### Check Service Status
```bash
sudo systemctl status portfolio
sudo systemctl is-enabled portfolio
sudo systemctl is-active portfolio
```

### View Service Logs
```bash
# View recent logs
sudo journalctl -u portfolio -n 50

# Follow logs in real-time
sudo journalctl -u portfolio -f

# View PM2 logs (as portfolio user)
sudo -u portfolio pm2 logs
sudo -u portfolio pm2 status
```

### Test Application
```bash
# Test if the application is responding
curl -f http://localhost:3000/
curl -f http://localhost:3001/health

# Check process is running
ps aux | grep node
sudo netstat -tulpn | grep :3000
```

## 4. Debugging Common Issues

### Issue: Service fails to start
```bash
# Check detailed error messages
sudo journalctl -u portfolio -n 100 --no-pager

# Check PM2 status
sudo -u portfolio pm2 list
sudo -u portfolio pm2 logs --err

# Verify ecosystem.config.js exists
ls -la /var/www/portfolio/ecosystem.config.js
```

### Issue: Permission denied errors
```bash
# Fix ownership
sudo chown -R portfolio:portfolio /var/www/portfolio
sudo chown -R portfolio:portfolio /var/log/portfolio

# Check directory permissions
ls -la /var/www/portfolio
```

### Issue: Port already in use
```bash
# Check what's using port 3000
sudo netstat -tulpn | grep :3000
sudo lsof -i :3000

# Kill process if needed
sudo pkill -f "node.*3000"
```

## 5. Manual Service Control

### Start/Stop/Restart Service
```bash
sudo systemctl start portfolio
sudo systemctl stop portfolio
sudo systemctl restart portfolio
sudo systemctl reload portfolio
```

### Disable/Enable Service
```bash
sudo systemctl disable portfolio
sudo systemctl enable portfolio
```

### Remove Service (Uninstall)
```bash
sudo systemctl stop portfolio
sudo systemctl disable portfolio
sudo rm /etc/systemd/system/portfolio.service
sudo systemctl daemon-reload
```

## 6. GitHub Actions Configuration

To fix the GitHub Actions failures, you need to configure the following secrets and variables in your GitHub repository:

### Required Repository Secrets

Go to GitHub Repository → Settings → Secrets and variables → Actions

**Secrets:**
- `PRODUCTION_HOST` - Your server's IP address or hostname
- `PRODUCTION_SSH_KEY` - Private SSH key for server access
- `PRODUCTION_USER` - SSH username (usually 'portfolio' or 'root')
- `PRODUCTION_PORT` - SSH port (default: 22)

**Optional Secrets (for staging):**
- `STAGING_HOST`
- `STAGING_SSH_KEY` 
- `STAGING_USER`
- `STAGING_PORT`
- `SLACK_WEBHOOK` - For deployment notifications

### Required Repository Variables

Go to GitHub Repository → Settings → Secrets and variables → Actions → Variables

**Variables:**
- `ENABLE_PRODUCTION_DEPLOY` - Set to 'true' to enable production deployments
- `ENABLE_STAGING_DEPLOY` - Set to 'true' to enable staging deployments  
- `PRODUCTION_URL` - Your production domain (e.g., 'https://yourdomain.com')
- `STAGING_URL` - Your staging domain (optional)

### Disable Deployment Jobs Temporarily

If you want to run the workflow without deployment, set these variables to 'false':
- `ENABLE_PRODUCTION_DEPLOY=false`
- `ENABLE_STAGING_DEPLOY=false`

This will allow the build and test jobs to run without attempting deployment.

## 7. Troubleshooting Checklist

- [ ] Is the script being run from the correct directory?
- [ ] Does the portfolio.service file exist in the project root?
- [ ] Is the script being run with sudo/root privileges?
- [ ] Are all required dependencies installed (Node.js, PM2, nginx)?
- [ ] Does the portfolio user exist and have correct permissions?
- [ ] Is the ecosystem.config.js file present and valid?
- [ ] Are the required GitHub secrets configured?
- [ ] Is the production server accessible via SSH?

## 8. Getting Help

If you continue to experience issues:

1. Check the application logs: `sudo journalctl -u portfolio -f`
2. Verify PM2 status: `sudo -u portfolio pm2 status`
3. Test network connectivity: `curl -f http://localhost:3000/`
4. Review the complete setup script output for specific error messages

Remember to replace placeholder values (like domain names and server addresses) with your actual configuration values.
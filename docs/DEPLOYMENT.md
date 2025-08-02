# Portfolio Deployment Guide

This document provides comprehensive instructions for deploying the portfolio website with zero-downtime deployment capabilities.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Methods](#deployment-methods)
- [Configuration](#configuration)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

## Overview

This portfolio website is designed for production deployment with the following features:

- **Zero-downtime deployments** using PM2 cluster mode
- **SSL/TLS termination** with automatic certificate renewal
- **Health checking** and monitoring
- **Load balancing** and reverse proxy with Nginx
- **Docker support** for containerized deployments
- **CI/CD pipeline** with GitHub Actions
- **Automatic rollback** capabilities

## Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04 LTS or later (recommended)
- **Node.js**: Version 18.0.0 or later
- **Memory**: Minimum 1GB RAM (2GB+ recommended)
- **Storage**: Minimum 10GB free space
- **Network**: Static IP address and domain name

### Required Software

```bash
# Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2@latest

# Install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# Install Docker (optional)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Quick Start

### 1. Initial Server Setup

```bash
# Clone the repository
git clone https://github.com/amirsalahshur/dev-resume.git
cd dev-resume

# Run the automated setup script
sudo bash scripts/setup-service.sh

# This script will:
# - Create the portfolio user and directories
# - Install systemd service
# - Configure log rotation
# - Set up firewall rules
# - Configure sudo permissions
```

### 2. Application Deployment

```bash
# Switch to portfolio user
sudo su - portfolio

# Navigate to application directory
cd /var/www/portfolio

# Copy your application code here
# (or pull from git repository)

# Install dependencies
npm ci --production

# Build the application
npm run build

# Start the application with PM2
npm run start:pm2

# Check application status
npm run status:pm2
```

### 3. Nginx Configuration

```bash
# Copy nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/portfolio
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/

# Update domain names in the configuration
sudo nano /etc/nginx/sites-available/portfolio
# Replace 'your-domain.com' with your actual domain

# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### 4. SSL Certificate Setup

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test automatic renewal
sudo certbot renew --dry-run
```

## Deployment Methods

### Method 1: Traditional Server Deployment

This is the recommended method for most production deployments.

#### Initial Setup

```bash
# 1. Server preparation
sudo bash scripts/setup-service.sh

# 2. Configure environment
cp .env.example .env
nano .env  # Update with your values

# 3. Deploy application
bash scripts/deploy.sh
```

#### Ongoing Deployments

```bash
# Zero-downtime deployment
sudo -u portfolio bash scripts/deploy.sh

# Check deployment status
sudo -u portfolio bash scripts/deploy.sh --status

# View logs
sudo -u portfolio bash scripts/deploy.sh --logs

# Rollback if needed
sudo -u portfolio bash scripts/deploy.sh --rollback
```

### Method 2: Docker Deployment

#### Using Docker Compose (Recommended)

```bash
# 1. Update environment variables
cp .env.example .env
nano .env

# 2. Update docker-compose.yml with your domain
nano docker-compose.yml

# 3. Start services
docker-compose up -d

# 4. Check status
docker-compose ps
docker-compose logs -f

# 5. SSL setup with Certbot
docker-compose exec certbot certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  --email your-email@domain.com \
  --agree-tos --no-eff-email \
  -d your-domain.com -d www.your-domain.com
```

#### Using Docker Standalone

```bash
# Build image
docker build -t portfolio:latest .

# Run container
docker run -d \
  --name portfolio \
  -p 3000:3000 \
  -p 3001:3001 \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  portfolio:latest
```

### Method 3: CI/CD Deployment

#### GitHub Actions Setup

1. **Configure Secrets**: Add the following secrets to your GitHub repository:

```
PRODUCTION_HOST=your-server-ip
PRODUCTION_USER=portfolio
PRODUCTION_SSH_KEY=your-private-ssh-key
PRODUCTION_PORT=22
STAGING_HOST=your-staging-server-ip
STAGING_USER=portfolio
STAGING_SSH_KEY=your-staging-private-ssh-key
SLACK_WEBHOOK=your-slack-webhook-url (optional)
```

2. **Deploy via GitHub Actions**:
   - Push to `main` branch → deploys to staging
   - Push to `production` branch → deploys to production
   - Manual deployment via workflow dispatch

#### Local CI/CD Commands

```bash
# Trigger production deployment
git push origin production

# Trigger staging deployment
git push origin main

# Manual deployment
gh workflow run deploy.yml -f environment=production
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and update the following critical variables:

```bash
# Domain configuration
DOMAIN=your-domain.com
WWW_DOMAIN=www.your-domain.com
LETSENCRYPT_EMAIL=your-email@domain.com

# Application configuration
NODE_ENV=production
PORT=3000
HEALTH_CHECK_PORT=3001

# PM2 configuration
PM2_INSTANCES=max
MEMORY_LIMIT=1G

# Security configuration
RATE_LIMIT_MAX=100
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

### PM2 Configuration

The `ecosystem.config.js` file contains PM2 configuration:

```javascript
module.exports = {
  apps: [{
    name: 'amir-portfolio',
    script: 'npm',
    args: 'run serve',
    instances: 'max',  // Use all CPU cores
    exec_mode: 'cluster',
    // ... additional configuration
  }]
};
```

### Nginx Configuration

Key configuration sections in `nginx.conf`:

- **SSL/TLS**: Modern cipher suites and security headers
- **Rate Limiting**: Protection against abuse
- **Compression**: Gzip and Brotli for performance
- **Security Headers**: CSP, HSTS, and other security measures
- **Health Checks**: Internal health check endpoints

## Monitoring and Maintenance

### Health Checks

```bash
# Check application health
curl http://localhost:3001/health

# Check main application
curl http://localhost:3000/

# Check PM2 status
pm2 status

# Check systemd service
systemctl status portfolio
```

### Log Management

```bash
# View application logs
pm2 logs amir-portfolio

# View system logs
journalctl -u portfolio -f

# View nginx logs
tail -f /var/log/nginx/portfolio_access.log
tail -f /var/log/nginx/portfolio_error.log

# View deployment logs
tail -f /var/log/portfolio/deploy.log
```

### Performance Monitoring

```bash
# PM2 monitoring
pm2 monit

# System resources
htop
iostat
df -h

# Network monitoring
netstat -tulpn
ss -tulpn
```

### Backup and Recovery

```bash
# Manual backup
sudo -u portfolio mkdir -p /var/backups/portfolio/$(date +%Y%m%d_%H%M%S)
sudo -u portfolio cp -r /var/www/portfolio/dist /var/backups/portfolio/$(date +%Y%m%d_%H%M%S)/

# Automated backup (included in deployment script)
sudo -u portfolio bash scripts/deploy.sh --backup

# List backups
ls -la /var/backups/portfolio/

# Restore from backup
sudo -u portfolio bash scripts/deploy.sh --rollback
```

## Troubleshooting

### Common Issues

#### Application Won't Start

```bash
# Check Node.js version
node --version  # Should be 18+

# Check PM2 status
pm2 status
pm2 logs

# Check build output
ls -la dist/
cat dist/index.html

# Restart application
pm2 restart amir-portfolio
```

#### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Test certificate renewal
sudo certbot renew --dry-run

# Manual certificate renewal
sudo certbot renew

# Check nginx SSL configuration
sudo nginx -t
openssl s_client -connect your-domain.com:443
```

#### Performance Issues

```bash
# Check system resources
free -h
df -h
top

# Check PM2 memory usage
pm2 monit

# Restart PM2 processes
pm2 restart amir-portfolio

# Check nginx status
sudo systemctl status nginx
```

#### Deployment Failures

```bash
# Check deployment logs
tail -f /var/log/portfolio/deploy.log

# Check git status
git status
git log --oneline -5

# Manual deployment steps
npm ci
npm run build
pm2 reload ecosystem.config.js
```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
# Set debug environment
export DEBUG=true
export LOG_LEVEL=debug

# Restart with debug logging
pm2 restart amir-portfolio
pm2 logs amir-portfolio --lines 100
```

## Security

### Security Checklist

- [ ] SSL/TLS certificates are valid and auto-renewing
- [ ] Security headers are properly configured
- [ ] Rate limiting is enabled
- [ ] Firewall rules are configured
- [ ] Application runs as non-root user
- [ ] Regular security updates are applied
- [ ] Access logs are monitored
- [ ] Backup encryption is enabled

### Security Updates

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade

# Update Node.js dependencies
npm audit
npm audit fix

# Update PM2
sudo npm update -g pm2

# Check for security vulnerabilities
npm run security-audit
```

### Firewall Configuration

```bash
# Check firewall status
sudo ufw status

# Allow necessary ports
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

## Additional Resources

### Useful Commands

```bash
# Service management
sudo systemctl start portfolio
sudo systemctl stop portfolio
sudo systemctl restart portfolio
sudo systemctl status portfolio

# PM2 management
pm2 start ecosystem.config.js --env production
pm2 stop amir-portfolio
pm2 restart amir-portfolio
pm2 reload amir-portfolio
pm2 delete amir-portfolio

# Docker management
docker-compose up -d
docker-compose down
docker-compose restart
docker-compose logs -f

# SSL certificate management
sudo certbot certificates
sudo certbot renew
sudo certbot delete --cert-name your-domain.com
```

### Performance Optimization

```bash
# Optimize application build
npm run optimize

# Clear PM2 logs
pm2 flush

# Optimize nginx
sudo nginx -s reload

# Clean Docker images
docker system prune -f
```

### Scaling Considerations

For high-traffic scenarios:

1. **Horizontal Scaling**: Use multiple servers with load balancer
2. **Database**: Add external database (PostgreSQL/MongoDB)
3. **CDN**: Implement CDN for static assets
4. **Caching**: Add Redis for application caching
5. **Monitoring**: Implement comprehensive monitoring (Prometheus/Grafana)

## Support

For issues and support:

- **Repository**: [GitHub Issues](https://github.com/amirsalahshur/dev-resume/issues)
- **Documentation**: Check this deployment guide
- **Logs**: Always include relevant log files when reporting issues

---

**Last Updated**: 2024-01-01  
**Version**: 2.0.0
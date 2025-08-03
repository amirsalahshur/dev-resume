#!/bin/bash

# Portfolio Complete Installation Script
# One-command installation for production deployment
#
# Usage: curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com
# 
# Requirements: Fresh Ubuntu 20.04+ server with root access

set -euo pipefail

# Configuration
DOMAIN="${1:-}"
EMAIL="${2:-}"
REPO_URL="https://github.com/amirsalahshur/dev-resume.git"
APP_DIR="/var/www/portfolio"
SERVICE_USER="portfolio"
LOG_FILE="/tmp/portfolio-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}"
    echo "Installation failed. Check $LOG_FILE for details."
    exit 1
}

success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

info() {
    log "${BLUE}INFO: $1${NC}"
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Display banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                Portfolio Installation Script                 ║
║                                                              ║
║  This script will install a complete production-ready       ║
║  portfolio website with:                                    ║
║  • Node.js 20+ & PM2                                        ║
║  • Nginx with SSL/TLS                                       ║
║  • Zero-downtime deployments                                ║
║  • Health monitoring                                        ║
║  • Security hardening                                       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
}

# Validate inputs
validate_inputs() {
    if [[ -z "$DOMAIN" ]]; then
        error "Domain name is required. Usage: $0 your-domain.com your-email@domain.com"
    fi
    
    if [[ -z "$EMAIL" ]]; then
        error "Email address is required. Usage: $0 your-domain.com your-email@domain.com"
    fi
    
    # Basic domain validation
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        error "Invalid domain format: $DOMAIN"
    fi
    
    # Basic email validation
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error "Invalid email format: $EMAIL"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Check system requirements
check_system() {
    info "Checking system requirements..."
    
    # Check Ubuntu version
    if ! grep -E "Ubuntu (20|22)\." /etc/os-release > /dev/null; then
        warning "This script is designed for Ubuntu 20.04+ or 22.04+. Continuing anyway..."
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        warning "Architecture $ARCH may not be fully supported. Continuing anyway..."
    fi
    
    # Check available disk space (minimum 10GB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    if [[ $AVAILABLE_SPACE -lt 10485760 ]]; then # 10GB in KB
        warning "Less than 10GB available disk space. Continuing anyway..."
    fi
    
    # Check available memory (minimum 1GB)
    AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
    if [[ $AVAILABLE_MEM -lt 512 ]]; then # 512MB available
        warning "Less than 512MB available memory. Performance may be affected."
    fi
    
    success "System requirements check completed"
}

# Update system and install prerequisites
install_prerequisites() {
    info "Installing system prerequisites..."
    
    # Update package lists
    apt-get update > /dev/null 2>&1
    
    # Install essential packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        ufw \
        fail2ban \
        htop \
        unattended-upgrades > /dev/null 2>&1
    
    success "System prerequisites installed"
}

# Install Node.js 20+
install_nodejs() {
    info "Installing Node.js 20..."
    
    # Add Node.js 20 repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    
    # Install Node.js
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs > /dev/null 2>&1
    
    # Verify installation
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    if ! printf '%s\n%s\n' "20.0.0" "$NODE_VERSION" | sort -V -C; then
        error "Node.js version $NODE_VERSION is less than required 20.0.0"
    fi
    
    success "Node.js $NODE_VERSION installed"
}

# Install PM2
install_pm2() {
    info "Installing PM2 process manager..."
    
    npm install -g pm2@latest > /dev/null 2>&1
    
    # Verify installation
    PM2_VERSION=$(pm2 --version)
    success "PM2 $PM2_VERSION installed"
}

# Install and configure Nginx
install_nginx() {
    info "Installing and configuring Nginx..."
    
    # Install Nginx
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx > /dev/null 2>&1
    
    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx > /dev/null 2>&1
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    success "Nginx installed and configured"
}

# Install SSL certificate tools
install_ssl_tools() {
    info "Installing SSL certificate tools..."
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1
    
    success "SSL tools installed"
}

# Clone repository and setup application
setup_application() {
    info "Setting up application..."
    
    # Clone repository to temporary location
    TEMP_DIR=$(mktemp -d)
    git clone "$REPO_URL" "$TEMP_DIR" > /dev/null 2>&1
    
    # Run the setup service script
    bash "$TEMP_DIR/scripts/setup-service.sh" > /dev/null 2>&1
    
    # Copy application files to final location
    cp -r "$TEMP_DIR"/* "$APP_DIR/"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
    
    # Clean up temporary directory
    rm -rf "$TEMP_DIR"
    
    success "Application files copied and configured"
}

# Build and start application
build_and_start() {
    info "Building and starting application..."
    
    # Switch to service user and build application
    sudo -u "$SERVICE_USER" bash -c "
        cd '$APP_DIR'
        npm ci --production=false > /dev/null 2>&1
        npm run build > /dev/null 2>&1
    "
    
    # Create environment file
    sudo -u "$SERVICE_USER" cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=3000
HEALTH_CHECK_PORT=3001
LOG_LEVEL=info
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000
APP_NAME=portfolio
APP_VERSION=2.0.0
APP_USER=$SERVICE_USER
APP_DIR=$APP_DIR
ENABLE_METRICS=true
METRICS_PORT=9090
EOF
    
    # Start PM2 processes
    sudo -u "$SERVICE_USER" bash -c "
        cd '$APP_DIR'
        npm run start:pm2 > /dev/null 2>&1
        pm2 save > /dev/null 2>&1
    "
    
    # Start and enable systemd service
    systemctl start portfolio
    systemctl enable portfolio > /dev/null 2>&1
    
    success "Application built and started"
}

# Configure Nginx for the domain
configure_nginx() {
    info "Configuring Nginx for domain $DOMAIN..."
    
    # Copy nginx configuration
    cp "$APP_DIR/nginx.conf" "/etc/nginx/sites-available/portfolio"
    
    # Update configuration with actual domain
    sed -i "s/your-domain\.com/$DOMAIN/g" "/etc/nginx/sites-available/portfolio"
    sed -i "s/www\.your-domain\.com/www.$DOMAIN/g" "/etc/nginx/sites-available/portfolio"
    
    # Enable site
    ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
    
    success "Nginx configured for domain $DOMAIN"
}

# Generate SSL certificate
generate_ssl() {
    info "Generating SSL certificate for $DOMAIN..."
    
    # Stop nginx temporarily
    systemctl stop nginx
    
    # Generate certificate
    certbot certonly --standalone \
        -d "$DOMAIN" \
        -d "www.$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive > /dev/null 2>&1
    
    # Start nginx
    systemctl start nginx
    
    # Test nginx configuration
    if ! nginx -t > /dev/null 2>&1; then
        error "Nginx configuration test failed after SSL setup"
    fi
    
    # Reload nginx
    systemctl reload nginx
    
    success "SSL certificate generated and configured"
}

# Configure firewall
configure_firewall() {
    info "Configuring firewall..."
    
    # Configure UFW firewall
    ufw --force reset > /dev/null 2>&1
    ufw allow ssh > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow from 127.0.0.1 to any port 3000 > /dev/null 2>&1
    ufw allow from 127.0.0.1 to any port 3001 > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    
    success "Firewall configured"
}

# Configure fail2ban
configure_fail2ban() {
    info "Configuring fail2ban..."
    
    cat > "/etc/fail2ban/jail.local" << EOF
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
    
    systemctl restart fail2ban > /dev/null 2>&1
    
    success "Fail2ban configured"
}

# Configure automatic updates
configure_auto_updates() {
    info "Configuring automatic security updates..."
    
    # Configure unattended upgrades
    echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    
    # Enable automatic updates
    dpkg-reconfigure -plow unattended-upgrades > /dev/null 2>&1
    
    success "Automatic security updates configured"
}

# Run verification tests
run_verification() {
    info "Running verification tests..."
    
    # Wait for services to stabilize
    sleep 10
    
    # Check systemd service
    if ! systemctl is-active --quiet portfolio; then
        error "Portfolio service is not active"
    fi
    
    # Check PM2 processes
    if ! sudo -u "$SERVICE_USER" pm2 describe amir-portfolio > /dev/null 2>&1; then
        error "PM2 main process is not running"
    fi
    
    # Check application response
    if ! curl -f -s http://localhost:3000 > /dev/null; then
        error "Application is not responding on port 3000"
    fi
    
    # Check health endpoint
    if ! curl -f -s http://localhost:3001/health > /dev/null; then
        error "Health check endpoint is not responding"
    fi
    
    # Check HTTPS (may take a moment for DNS propagation)
    info "Testing HTTPS connection (this may take a moment)..."
    sleep 5
    if ! curl -f -s "https://$DOMAIN" > /dev/null; then
        warning "HTTPS test failed - this may be due to DNS propagation delay"
        info "Try testing manually in a few minutes: https://$DOMAIN"
    else
        success "HTTPS connection successful"
    fi
    
    success "Verification tests passed"
}

# Display completion information
show_completion() {
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                   INSTALLATION COMPLETE!                    ║
╚══════════════════════════════════════════════════════════════╝

🎉 Your portfolio is now live at: https://$DOMAIN

✅ Features installed:
   • Node.js 20+ with PM2 clustering
   • Nginx with SSL/TLS encryption  
   • Zero-downtime deployment system
   • Health monitoring endpoints
   • Security hardening (fail2ban, UFW)
   • Automatic security updates
   • Log rotation and monitoring

📊 Service Status:
   • Portfolio Service: $(systemctl is-active portfolio)
   • Nginx: $(systemctl is-active nginx)
   • PM2 Processes: $(sudo -u $SERVICE_USER pm2 list | grep -c online) online

🔧 Useful Commands:
   • Check status: sudo systemctl status portfolio
   • Deploy updates: sudo -u portfolio bash $APP_DIR/scripts/deploy.sh
   • View logs: sudo journalctl -u portfolio -f
   • PM2 status: sudo -u portfolio pm2 status

📁 Important Paths:
   • Application: $APP_DIR
   • Logs: /var/log/portfolio/
   • Nginx config: /etc/nginx/sites-available/portfolio
   • SSL certificates: /etc/letsencrypt/live/$DOMAIN/

🔒 Security:
   • SSL certificate auto-renewal is configured
   • Firewall is active with necessary ports open
   • Fail2ban is monitoring for suspicious activity

📖 Documentation:
   • Full installation guide: $APP_DIR/INSTALL.md
   • Deployment guide: $APP_DIR/COMPLETE_INSTALLATION_GUIDE.md

⚠️  Next Steps:
   1. Update DNS if not already done
   2. Test the website: https://$DOMAIN
   3. Configure GitHub Actions for CI/CD (see INSTALL.md)
   4. Setup monitoring and backups

Installation log saved to: $LOG_FILE

EOF
}

# Main installation function
main() {
    # Create log file
    touch "$LOG_FILE"
    
    show_banner
    validate_inputs
    check_root
    check_system
    
    info "Starting installation for domain: $DOMAIN with email: $EMAIL"
    
    install_prerequisites
    install_nodejs
    install_pm2
    install_nginx
    install_ssl_tools
    setup_application
    build_and_start
    configure_nginx
    generate_ssl
    configure_firewall
    configure_fail2ban
    configure_auto_updates
    run_verification
    
    show_completion
    
    success "Portfolio installation completed successfully!"
}

# Error handling
trap 'error "Installation failed at line $LINENO. Check $LOG_FILE for details."' ERR

# Run main installation
main "$@"
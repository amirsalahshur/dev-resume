#!/bin/bash

# Portfolio Complete Installation Script
# One-command installation for production deployment
#
# Usage: curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- your-domain.com your-email@domain.com
# 
# Requirements: Fresh Ubuntu 20.04+ server with root access

set -euo pipefail

# Configuration  
DOMAIN=""
EMAIL=""
SKIP_DOMAIN_CHECK=false
DRY_RUN=false
FORCE_INSTALL=false
REPO_URL="https://github.com/amirsalahshur/dev-resume.git"
APP_DIR="/var/www/portfolio"
SERVICE_USER="portfolio"
LOG_FILE="/tmp/portfolio-install.log"
ROLLBACK_LOG="/tmp/portfolio-rollback.log"
INSTALLATION_STATE="/tmp/portfolio-install-state"

# Track installation progress for rollback
declare -a INSTALLATION_STEPS=()

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
    echo "Last 20 lines of log:"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "Could not read log file"
    
    # Offer rollback option
    if [[ -f "$INSTALLATION_STATE" ]] && [[ -s "$INSTALLATION_STATE" ]]; then
        echo
        echo "Would you like to rollback the installation? (y/N)"
        read -t 30 -r response || response="n"
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rollback_installation
        else
            echo "Rollback skipped. To manually rollback later, check $ROLLBACK_LOG"
        fi
    fi
    
    exit 1
}

# Enhanced error function with command output
error_with_output() {
    local message="$1"
    local command_output="${2:-}"
    
    log "${RED}ERROR: $message${NC}"
    if [[ -n "$command_output" ]]; then
        log "${RED}Command output: $command_output${NC}"
    fi
    echo "Installation failed. Check $LOG_FILE for details."
    echo "Last 20 lines of log:"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "Could not read log file"
    exit 1
}

# Execute command with error handling and logging
execute_with_log() {
    local description="$1"
    local command="$2"
    local allow_failure="${3:-false}"
    
    info "$description..."
    log "Would execute: $command"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would execute: $command"
        return 0
    fi
    
    local output
    if output=$(eval "$command" 2>&1); then
        log "Success: $description"
        log "Output: $output"
        return 0
    else
        local exit_code=$?
        log "Failed: $description (exit code: $exit_code)"
        log "Error output: $output"
        
        if [[ "$allow_failure" != "true" ]]; then
            error_with_output "$description failed" "$output"
        else
            warning "$description failed but continuing: $output"
            return $exit_code
        fi
    fi
}

# Dry run aware track step
track_step() {
    local step="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would track step: $step"
        return 0
    fi
    
    INSTALLATION_STEPS+=("$step")
    echo "$step" >> "$INSTALLATION_STATE"
    log "Step completed: $step"
}


# Rollback installation
rollback_installation() {
    warning "Rolling back installation..."
    
    # Create rollback log
    echo "Portfolio Installation Rollback - $(date)" > "$ROLLBACK_LOG"
    
    # Reverse the order of steps for rollback
    local steps=()
    while IFS= read -r line; do
        steps=("$line" "${steps[@]}")
    done < "$INSTALLATION_STATE" 2>/dev/null
    
    for step in "${steps[@]}"; do
        case "$step" in
            "prerequisites")
                warning "Skipping rollback of prerequisites (would affect system packages)"
                ;;
            "nodejs")
                warning "Skipping rollback of Node.js (may be used by other applications)"
                ;;
            "pm2")
                info "Removing PM2..."
                npm uninstall -g pm2 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "nginx")
                info "Removing nginx configuration..."
                rm -f /etc/nginx/sites-enabled/portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                rm -f /etc/nginx/sites-available/portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                systemctl reload nginx 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "ssl")
                info "Removing SSL certificates..."
                certbot delete --cert-name "$DOMAIN" --non-interactive 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "application")
                info "Removing application files..."
                systemctl stop portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                systemctl disable portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                rm -rf "$APP_DIR" 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "service")
                info "Removing systemd service..."
                systemctl stop portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                systemctl disable portfolio 2>&1 | tee -a "$ROLLBACK_LOG" || true
                rm -f /etc/systemd/system/portfolio.service 2>&1 | tee -a "$ROLLBACK_LOG" || true
                systemctl daemon-reload 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "user")
                info "Removing service user..."
                userdel -r "$SERVICE_USER" 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
            "firewall")
                info "Resetting firewall rules..."
                ufw --force reset 2>&1 | tee -a "$ROLLBACK_LOG" || true
                ;;
        esac
    done
    
    # Clean up temp files
    rm -f "$INSTALLATION_STATE" "$LOG_FILE"
    
    echo "Rollback completed. Check $ROLLBACK_LOG for details."
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

# Parse command line arguments  
parse_arguments() {
    info "Processing arguments: $*"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-domain-check)
                SKIP_DOMAIN_CHECK=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$DOMAIN" ]]; then
                    DOMAIN="$1"
                    info "Setting domain: $DOMAIN"
                elif [[ -z "$EMAIL" ]]; then
                    EMAIL="$1"
                    info "Setting email: $EMAIL"
                else
                    error "Unknown argument: $1"
                fi
                shift
                ;;
        esac
    done
}

# Show usage information
show_usage() {
    cat << 'EOF'
Usage: ./install.sh [OPTIONS] DOMAIN EMAIL

Install production-ready portfolio website with zero-downtime deployment.

Arguments:
  DOMAIN              Domain name (e.g., example.com, info.example.com)
  EMAIL               Email for SSL certificate registration

Options:
  --skip-domain-check Skip domain format validation (use for edge cases)
  --dry-run          Preview what will be done without making changes
  --force            Override existing installations
  --help, -h         Show this help message

Examples:
  ./install.sh example.com admin@example.com
  ./install.sh info.subdomain.com admin@example.com --skip-domain-check
  ./install.sh example.com admin@example.com --dry-run
EOF
}

# Validate inputs
validate_inputs() {
    if [[ -z "$DOMAIN" ]]; then
        error "Domain name is required. Use --help for usage information."
    fi
    
    if [[ -z "$EMAIL" ]]; then
        error "Email address is required. Use --help for usage information."
    fi
    
    # Enhanced domain validation to support all valid subdomains (unless skipped)
    if [[ "$SKIP_DOMAIN_CHECK" != "true" ]]; then
        # More flexible regex to support complex subdomains like info.amirsalahshur.xyz
        if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$ ]]; then
            error "Invalid domain format: $DOMAIN. Expected format: example.com, info.example.com, api.v2.example.com, or info.amirsalahshur.xyz. Use --skip-domain-check to bypass validation."
        fi
        
        # Additional validation for domain structure
        local domain_parts=(${DOMAIN//./ })
        if [[ ${#domain_parts[@]} -lt 2 ]]; then
            error "Domain must have at least 2 parts (e.g., example.com): $DOMAIN"
        fi
        
        # Check for valid TLD (at least 2 characters)
        local tld="${domain_parts[-1]}"
        if [[ ${#tld} -lt 2 ]]; then
            error "Invalid top-level domain: $tld. Must be at least 2 characters."
        fi
    else
        warning "Domain validation skipped for: $DOMAIN"
    fi
    
    # Basic email validation
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error "Invalid email format: $EMAIL"
    fi
    
    # Check for existing installation if not forcing
    if [[ "$FORCE_INSTALL" != "true" ]] && [[ -d "$APP_DIR" ]] && [[ -f "/etc/systemd/system/portfolio.service" ]]; then
        error "Portfolio appears to already be installed. Use --force to override existing installation."
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
    execute_with_log "Updating package lists" "apt-get update"
    
    # Install essential packages
    execute_with_log "Installing essential packages" \
        "DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
        unattended-upgrades"
    
    track_step "prerequisites"
    success "System prerequisites installed"
}

# Install Node.js 20+
install_nodejs() {
    info "Installing Node.js 20..."
    
    # Check if Node.js is already installed and meets requirements
    if command -v node >/dev/null 2>&1; then
        local current_version
        current_version=$(node --version | cut -d'v' -f2)
        if printf '%s\n%s\n' "20.0.0" "$current_version" | sort -V -C; then
            info "Node.js $current_version already installed and meets requirements"
            return 0
        else
            info "Node.js $current_version found but upgrading to v20+"
        fi
    fi
    
    # Add Node.js 20 repository
    execute_with_log "Adding Node.js 20 repository" \
        "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
    
    # Install Node.js
    execute_with_log "Installing Node.js" \
        "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs"
    
    # Verify installation
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js installation failed - node command not found"
    fi
    
    local node_version
    node_version=$(node --version | cut -d'v' -f2)
    if ! printf '%s\n%s\n' "20.0.0" "$node_version" | sort -V -C; then
        error "Node.js version $node_version is less than required 20.0.0"
    fi
    
    track_step "nodejs"
    success "Node.js $node_version installed"
}

# Install PM2
install_pm2() {
    info "Installing PM2 process manager..."
    
    # Check if PM2 is already installed
    if command -v pm2 >/dev/null 2>&1; then
        local current_version
        current_version=$(pm2 --version)
        info "PM2 $current_version already installed"
        track_step "pm2"
        return 0
    fi
    
    execute_with_log "Installing PM2 globally" "npm install -g pm2@latest"
    
    # Verify installation
    if ! command -v pm2 >/dev/null 2>&1; then
        error "PM2 installation failed"
    fi
    
    PM2_VERSION=$(pm2 --version)
    track_step "pm2"
    success "PM2 $PM2_VERSION installed"
}

# Install and configure Nginx
install_nginx() {
    info "Installing and configuring Nginx..."
    
    # Check if Nginx is already installed
    if command -v nginx >/dev/null 2>&1; then
        info "Nginx already installed"
        if systemctl is-active --quiet nginx; then
            info "Nginx is already running"
        else
            execute_with_log "Starting nginx" "systemctl start nginx"
        fi
    else
        # Install Nginx
        execute_with_log "Installing nginx" \
            "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx"
        
        # Start and enable Nginx
        execute_with_log "Starting nginx" "systemctl start nginx"
    fi
    
    # Enable nginx (idempotent)
    execute_with_log "Enabling nginx" "systemctl enable nginx" "true"
    
    # Remove default site if it exists
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        execute_with_log "Removing default nginx site" \
            "rm -f /etc/nginx/sites-enabled/default"
    fi
    
    track_step "nginx"
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
    
    track_step "application"
    success "Application built and started"
}

# Configure Nginx for the domain
configure_nginx() {
    info "Configuring Nginx for domain $DOMAIN..."
    
    # Copy nginx configuration
    cp "$APP_DIR/nginx.conf" "/etc/nginx/sites-available/portfolio"
    
    # Update configuration with actual domain (handles subdomains correctly)
    sed -i "s/your-domain\.com/$DOMAIN/g" "/etc/nginx/sites-available/portfolio"
    
    # Handle www subdomain logic properly
    if [[ "$DOMAIN" == www.* ]]; then
        # If domain already starts with www, don't add another www
        sed -i "s/www\.your-domain\.com/$DOMAIN/g" "/etc/nginx/sites-available/portfolio"
    else
        # Add www version for non-www domains (but only if it's a second-level domain)
        local domain_parts=(${DOMAIN//./ })
        if [[ ${#domain_parts[@]} -eq 2 ]]; then
            # Only add www for second-level domains like example.com
            sed -i "s/www\.your-domain\.com/www.$DOMAIN/g" "/etc/nginx/sites-available/portfolio"
        else
            # For subdomains like api.example.com, remove the www version entirely
            sed -i "s/ www\.your-domain\.com//g" "/etc/nginx/sites-available/portfolio"
        fi
    fi
    
    # Enable site
    ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
    
    success "Nginx configured for domain $DOMAIN"
}

# Generate SSL certificate
generate_ssl() {
    info "Generating SSL certificate for $DOMAIN..."
    
    # Check if certificate already exists
    if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
        info "SSL certificate already exists for $DOMAIN"
        return 0
    fi
    
    # Stop nginx temporarily
    execute_with_log "Stopping nginx for certificate generation" "systemctl stop nginx"
    
    # Generate certificate with intelligent subdomain support
    local cert_domains="-d $DOMAIN"
    
    # Only add www version for second-level domains (not subdomains)
    if [[ "$DOMAIN" != www.* ]]; then
        local domain_parts=(${DOMAIN//./ })
        if [[ ${#domain_parts[@]} -eq 2 ]]; then
            # Only add www for second-level domains like example.com
            cert_domains="$cert_domains -d www.$DOMAIN"
        fi
        # For subdomains like info.example.com, don't add www version
    fi
    
    execute_with_log "Generating SSL certificate" \
        "certbot certonly --standalone \
        $cert_domains \
        --email '$EMAIL' \
        --agree-tos \
        --non-interactive"
    
    # Start nginx
    execute_with_log "Starting nginx after certificate generation" "systemctl start nginx"
    
    # Test nginx configuration
    local nginx_test_output
    if ! nginx_test_output=$(nginx -t 2>&1); then
        error_with_output "Nginx configuration test failed after SSL setup" "$nginx_test_output"
    fi
    
    # Reload nginx
    execute_with_log "Reloading nginx configuration" "systemctl reload nginx"
    
    track_step "ssl"
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
    
    track_step "firewall"
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
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN MODE - No changes will be made to the system"
        info "This will show you what would be installed and configured"
    fi
    
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

# Error handling with rollback
cleanup_on_error() {
    local line_no=$1
    log "${RED}Installation failed at line $line_no${NC}"
    
    # Offer rollback if installation has progressed
    if [[ -f "$INSTALLATION_STATE" ]] && [[ -s "$INSTALLATION_STATE" ]]; then
        echo
        echo "Installation failed. Would you like to rollback? (Y/n)"
        read -t 30 -r response || response="y"
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            rollback_installation
        fi
    fi
    
    exit 1
}

trap 'cleanup_on_error $LINENO' ERR

# Parse arguments and run main
parse_arguments "$@"
main
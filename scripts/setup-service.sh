#!/bin/bash

# Portfolio Service Setup Script
# This script sets up the systemd service and creates necessary users/directories

set -euo pipefail

# Configuration
SERVICE_NAME="portfolio"
SERVICE_USER="portfolio"
SERVICE_GROUP="portfolio"
APP_DIR="/var/www/portfolio"
LOG_DIR="/var/log/portfolio"
SERVICE_FILE="portfolio.service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "${RED}ERROR: $1${NC}"
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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Install prerequisites
install_prerequisites() {
    info "Installing prerequisites..."
    
    # Update package lists
    apt-get update
    
    # Install Node.js (if not already installed)
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install PM2 globally
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2@latest
    fi
    
    # Install nginx (if not already installed)
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
    fi
    
    # Install other dependencies
    apt-get install -y curl wget git sudo logrotate
    
    success "Prerequisites installed"
}

# Create service user and group
create_user() {
    info "Creating service user and group..."
    
    # Create group if it doesn't exist
    if ! getent group "$SERVICE_GROUP" > /dev/null 2>&1; then
        groupadd --system "$SERVICE_GROUP"
        success "Created group: $SERVICE_GROUP"
    else
        info "Group $SERVICE_GROUP already exists"
    fi
    
    # Create user if it doesn't exist
    if ! getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
        useradd --system \
                --gid "$SERVICE_GROUP" \
                --create-home \
                --home-dir "$APP_DIR" \
                --shell /bin/bash \
                --comment "Portfolio application user" \
                "$SERVICE_USER"
        success "Created user: $SERVICE_USER"
    else
        info "User $SERVICE_USER already exists"
    fi
}

# Create directories
create_directories() {
    info "Creating application directories..."
    
    # Create application directory
    mkdir -p "$APP_DIR"
    chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR"
    chmod 755 "$APP_DIR"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Create PM2 directory
    mkdir -p "$APP_DIR/.pm2"
    chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR/.pm2"
    chmod 755 "$APP_DIR/.pm2"
    
    # Create logs subdirectory
    mkdir -p "$APP_DIR/logs"
    chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR/logs"
    chmod 755 "$APP_DIR/logs"
    
    # Create backup directory
    mkdir -p "/var/backups/portfolio"
    chown "$SERVICE_USER:$SERVICE_GROUP" "/var/backups/portfolio"
    chmod 755 "/var/backups/portfolio"
    
    success "Directories created"
}

# Install systemd service
install_service() {
    info "Installing systemd service..."
    
    # Check if service file exists
    if [[ ! -f "$SERVICE_FILE" ]]; then
        error "Service file $SERVICE_FILE not found in current directory"
    fi
    
    # Copy service file
    cp "$SERVICE_FILE" "/etc/systemd/system/"
    chmod 644 "/etc/systemd/system/$SERVICE_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable "$SERVICE_NAME"
    
    success "Systemd service installed and enabled"
}

# Setup log rotation
setup_logrotate() {
    info "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/$SERVICE_NAME" << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_GROUP
    postrotate
        systemctl reload $SERVICE_NAME || true
    endscript
}

$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_GROUP
    postrotate
        sudo -u $SERVICE_USER pm2 reloadLogs || true
    endscript
}
EOF
    
    success "Log rotation configured"
}

# Setup sudo permissions
setup_sudo() {
    info "Setting up sudo permissions..."
    
    cat > "/etc/sudoers.d/$SERVICE_NAME" << EOF
# Allow portfolio user to manage nginx and own service
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl reload nginx
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl restart nginx
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl status nginx
$SERVICE_USER ALL=(root) NOPASSWD: /usr/sbin/nginx -t
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl reload $SERVICE_NAME
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl restart $SERVICE_NAME
$SERVICE_USER ALL=(root) NOPASSWD: /bin/systemctl status $SERVICE_NAME
EOF
    
    chmod 440 "/etc/sudoers.d/$SERVICE_NAME"
    
    success "Sudo permissions configured"
}

# Setup nginx user permissions
setup_nginx() {
    info "Configuring nginx..."
    
    # Add nginx user to portfolio group for log access
    usermod -a -G "$SERVICE_GROUP" www-data
    
    # Create nginx configuration directory
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    # Remove default nginx site
    rm -f /etc/nginx/sites-enabled/default
    
    success "Nginx configured"
}

# Create environment file
create_env_file() {
    info "Creating environment configuration..."
    
    cat > "$APP_DIR/.env" << EOF
# Portfolio Application Environment Configuration
NODE_ENV=production
PORT=3000
HEALTH_CHECK_PORT=3001
LOG_LEVEL=info
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000

# Application specific
APP_NAME=$SERVICE_NAME
APP_VERSION=2.0.0
APP_USER=$SERVICE_USER
APP_DIR=$APP_DIR

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
EOF
    
    chown "$SERVICE_USER:$SERVICE_GROUP" "$APP_DIR/.env"
    chmod 640 "$APP_DIR/.env"
    
    success "Environment file created"
}

# Setup firewall rules
setup_firewall() {
    info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Allow SSH (if not already allowed)
        ufw allow ssh
        
        # Allow HTTP and HTTPS
        ufw allow 80/tcp
        ufw allow 443/tcp
        
        # Allow application ports (from localhost only)
        ufw allow from 127.0.0.1 to any port 3000
        ufw allow from 127.0.0.1 to any port 3001
        
        # Enable firewall if not already enabled
        ufw --force enable
        
        success "Firewall configured"
    else
        warning "UFW not installed, skipping firewall configuration"
    fi
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    # Check user exists
    if getent passwd "$SERVICE_USER" > /dev/null; then
        success "User $SERVICE_USER exists"
    else
        error "User $SERVICE_USER not found"
    fi
    
    # Check directories exist and have correct permissions
    if [[ -d "$APP_DIR" ]] && [[ "$(stat -c %U:%G "$APP_DIR")" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        success "Application directory configured correctly"
    else
        error "Application directory not configured correctly"
    fi
    
    # Check service is installed
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        success "Systemd service installed"
    else
        error "Systemd service not installed"
    fi
    
    # Check service is enabled
    if systemctl is-enabled "$SERVICE_NAME" > /dev/null; then
        success "Service is enabled"
    else
        error "Service is not enabled"
    fi
    
    success "Installation verification completed"
}

# Display next steps
show_next_steps() {
    info "Installation completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Copy your application code to $APP_DIR"
    echo "2. Install application dependencies: sudo -u $SERVICE_USER npm install"
    echo "3. Build the application: sudo -u $SERVICE_USER npm run build"
    echo "4. Configure nginx with the provided nginx.conf"
    echo "5. Start the service: systemctl start $SERVICE_NAME"
    echo "6. Check service status: systemctl status $SERVICE_NAME"
    echo
    echo "Useful commands:"
    echo "  - View logs: journalctl -u $SERVICE_NAME -f"
    echo "  - Restart service: systemctl restart $SERVICE_NAME"
    echo "  - Check PM2 status: sudo -u $SERVICE_USER pm2 status"
    echo "  - Deploy: sudo -u $SERVICE_USER ./scripts/deploy.sh"
}

# Main installation function
main() {
    info "Starting portfolio service setup..."
    
    check_root
    install_prerequisites
    create_user
    create_directories
    install_service
    setup_logrotate
    setup_sudo
    setup_nginx
    create_env_file
    setup_firewall
    verify_installation
    show_next_steps
    
    success "Portfolio service setup completed!"
}

# Handle command line arguments
case "${1:-}" in
    --uninstall)
        info "Uninstalling portfolio service..."
        systemctl stop "$SERVICE_NAME" || true
        systemctl disable "$SERVICE_NAME" || true
        rm -f "/etc/systemd/system/$SERVICE_FILE"
        rm -f "/etc/logrotate.d/$SERVICE_NAME"
        rm -f "/etc/sudoers.d/$SERVICE_NAME"
        systemctl daemon-reload
        success "Service uninstalled"
        ;;
    --status)
        systemctl status "$SERVICE_NAME"
        ;;
    *)
        main "$@"
        ;;
esac
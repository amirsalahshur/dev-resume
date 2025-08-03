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
REPAIR_MODE=false
DRY_RUN=false

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
    
    # Install Node.js 20+ (if not already installed)
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    else
        # Check Node.js version
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        REQUIRED_VERSION="20.0.0"
        if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V -C; then
            warning "Node.js version $NODE_VERSION is less than required $REQUIRED_VERSION"
            info "Upgrading Node.js to version 20..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            apt-get install -y nodejs
        fi
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

# Retry function for systemd operations
retry_systemd_operation() {
    local operation="$1"
    local max_attempts=3
    local attempt=1
    local delay=2
    
    while [[ $attempt -le $max_attempts ]]; do
        info "Attempting $operation (attempt $attempt/$max_attempts)..."
        
        if eval "$operation"; then
            success "$operation completed successfully"
            return 0
        else
            if [[ $attempt -lt $max_attempts ]]; then
                warning "$operation failed, retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))  # Exponential backoff
            else
                error "$operation failed after $max_attempts attempts"
                return 1
            fi
        fi
        
        ((attempt++))
    done
}

# Install systemd service
install_service() {
    info "Installing systemd service..."
    
    # Stop service if it's already running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Stopping existing $SERVICE_NAME service..."
        systemctl stop "$SERVICE_NAME" || warning "Failed to stop existing service"
    fi
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    SERVICE_PATH="$PROJECT_DIR/$SERVICE_FILE"
    
    # Check if service file exists in project directory
    if [[ ! -f "$SERVICE_PATH" ]]; then
        # Try current directory as fallback
        if [[ ! -f "$SERVICE_FILE" ]]; then
            error "Service file $SERVICE_FILE not found in $PROJECT_DIR or current directory"
        else
            SERVICE_PATH="$SERVICE_FILE"
        fi
    fi
    
    info "Using service file: $SERVICE_PATH"
    
    # Validate service file content
    if ! grep -q "portfolio" "$SERVICE_PATH"; then
        error "Service file appears to be invalid (missing portfolio reference)"
    fi
    
    # Copy service file
    info "Copying service file to systemd directory..."
    cp "$SERVICE_PATH" "/etc/systemd/system/" || error "Failed to copy service file"
    chmod 644 "/etc/systemd/system/$SERVICE_FILE" || error "Failed to set service file permissions"
    
    # Reload systemd and wait for processing
    info "Reloading systemd daemon..."
    if ! systemctl daemon-reload; then
        error "Failed to reload systemd daemon"
    fi
    
    # Give systemd time to process the new service file
    info "Waiting for systemd to process changes..."
    sleep 3
    
    # Verify service file is recognized
    local retries=5
    while [[ $retries -gt 0 ]]; do
        if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
            success "Service file recognized by systemd"
            break
        else
            warning "Service not yet recognized, waiting..."
            sleep 2
            systemctl daemon-reload
            ((retries--))
        fi
    done
    
    if [[ $retries -eq 0 ]]; then
        error "Service file not recognized by systemd after multiple attempts"
    fi
    
    # Enable service with retry logic
    info "Enabling $SERVICE_NAME service..."
    retry_systemd_operation "systemctl enable $SERVICE_NAME"
    
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
    local verification_failed=false
    
    # Force systemd to refresh before verification
    info "Refreshing systemd state before verification..."
    systemctl daemon-reload
    sleep 2
    
    # Check user exists
    if getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
        success "✓ User $SERVICE_USER exists"
    else
        error "✗ User $SERVICE_USER not found"
        verification_failed=true
    fi
    
    # Check directories exist and have correct permissions
    if [[ -d "$APP_DIR" ]] && [[ "$(stat -c %U:%G "$APP_DIR" 2>/dev/null)" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        success "✓ Application directory configured correctly"
    else
        error "✗ Application directory not configured correctly"
        if [[ -d "$APP_DIR" ]]; then
            error "   Current ownership: $(stat -c %U:%G "$APP_DIR" 2>/dev/null || echo "unknown")"
        else
            error "   Directory does not exist: $APP_DIR"
        fi
        verification_failed=true
    fi
    
    # Check service file exists in systemd
    if [[ -f "/etc/systemd/system/$SERVICE_FILE" ]]; then
        success "✓ Service file copied to systemd"
    else
        error "✗ Service file not found in /etc/systemd/system/"
        verification_failed=true
    fi
    
    # Check service is installed (with detailed error output)
    local service_check_output
    service_check_output=$(systemctl list-unit-files "$SERVICE_NAME.service" 2>&1)
    if echo "$service_check_output" | grep -q "$SERVICE_NAME.service"; then
        success "✓ Systemd service installed"
    else
        error "✗ Systemd service not installed"
        error "   systemctl output: $service_check_output"
        verification_failed=true
    fi
    
    # Check service is enabled (with detailed error output)
    local enable_check_output
    enable_check_output=$(systemctl is-enabled "$SERVICE_NAME" 2>&1)
    if [[ "$enable_check_output" == "enabled" ]]; then
        success "✓ Service is enabled"
    else
        error "✗ Service is not enabled"
        error "   Current state: $enable_check_output"
        # Show systemctl status for more details
        local status_output
        status_output=$(systemctl status "$SERVICE_NAME" 2>&1 || true)
        error "   Service status: $status_output"
        verification_failed=true
    fi
    
    # Check PM2 is installed
    if command -v pm2 > /dev/null 2>&1; then
        success "✓ PM2 is installed"
    else
        error "✗ PM2 is not installed or not in PATH"
        verification_failed=true
    fi
    
    # Check ecosystem.config.js exists in project
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    if [[ -f "$PROJECT_DIR/ecosystem.config.js" ]]; then
        success "✓ ecosystem.config.js found"
    else
        warning "⚠ ecosystem.config.js not found in $PROJECT_DIR (required for PM2)"
    fi
    
    if [[ "$verification_failed" == "true" ]]; then
        error "Installation verification failed - see errors above"
        info "Troubleshooting steps:"
        info "1. Check systemd logs: journalctl -u $SERVICE_NAME"
        info "2. Verify service file: cat /etc/systemd/system/$SERVICE_FILE"
        info "3. Re-run daemon-reload: systemctl daemon-reload"
        info "4. Check service status: systemctl status $SERVICE_NAME"
        return 1
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

# Execute command with dry run support
execute_command() {
    local description="$1"
    local command="$2"
    local allow_failure="${3:-false}"
    
    info "$description..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would execute: $command"
        return 0
    fi
    
    if eval "$command"; then
        return 0
    else
        local exit_code=$?
        if [[ "$allow_failure" == "true" ]]; then
            warning "$description failed but continuing"
            return $exit_code
        else
            error "$description failed"
        fi
    fi
}

# Main installation function
main() {
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN MODE - No changes will be made to the system"
        info "This will show you what would be configured"
    fi
    
    if [[ "$REPAIR_MODE" == "true" ]]; then
        info "Starting portfolio service repair..."
        repair_installation
    else
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
    fi
}

# Repair broken installation
repair_installation() {
    info "Diagnosing and repairing portfolio service installation..."
    
    check_root
    
    # Check and repair user/group
    if ! getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
        warning "User $SERVICE_USER not found, creating..."
        create_user
    else
        success "✓ User $SERVICE_USER exists"
    fi
    
    # Check and repair directories
    if [[ ! -d "$APP_DIR" ]] || [[ "$(stat -c %U:%G "$APP_DIR" 2>/dev/null)" != "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        warning "Application directory issues found, fixing..."
        create_directories
    else
        success "✓ Directories are configured correctly"
    fi
    
    # Check and repair service installation
    if [[ ! -f "/etc/systemd/system/$SERVICE_FILE" ]] || ! systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        warning "Service installation issues found, reinstalling..."
        install_service
    else
        # Try to fix service issues
        info "Reloading systemd configuration..."
        systemctl daemon-reload
        sleep 2
        
        if ! systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            warning "Service not enabled, enabling..."
            retry_systemd_operation "systemctl enable $SERVICE_NAME"
        fi
        
        success "✓ Service installation repaired"
    fi
    
    # Repair other components
    setup_logrotate
    setup_sudo
    setup_nginx
    create_env_file
    
    # Final verification
    verify_installation
    
    success "Portfolio service repair completed!"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repair)
                REPAIR_MODE=true
                info "Repair mode enabled - will fix broken installations"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                info "Dry run mode enabled - no changes will be made"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            --uninstall)
                uninstall_service
                exit 0
                ;;
            --status)
                systemctl status "$SERVICE_NAME"
                exit 0
                ;;
            *)
                error "Unknown argument: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Show usage information
show_usage() {
    cat << 'EOF'
Usage: ./setup-service.sh [OPTIONS]

Setup systemd service for portfolio application.

Options:
  --repair           Fix broken installations and service issues
  --dry-run          Preview what will be done without making changes
  --uninstall        Remove the portfolio service completely
  --status           Show current service status
  --help, -h         Show this help message

Examples:
  ./setup-service.sh                    # Normal setup
  ./setup-service.sh --repair           # Fix broken installation
  ./setup-service.sh --dry-run          # Preview changes
  ./setup-service.sh --uninstall        # Remove service
EOF
}

# Uninstall service
uninstall_service() {
    info "Uninstalling portfolio service..."
    
    # Stop service if running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Stopping $SERVICE_NAME service..."
        systemctl stop "$SERVICE_NAME" || true
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        info "Disabling $SERVICE_NAME service..."
        systemctl disable "$SERVICE_NAME" || true
    fi
    
    # Remove service files
    rm -f "/etc/systemd/system/$SERVICE_FILE"
    rm -f "/etc/logrotate.d/$SERVICE_NAME"
    rm -f "/etc/sudoers.d/$SERVICE_NAME"
    
    # Reload systemd
    systemctl daemon-reload
    
    success "Service uninstalled successfully"
}

# Handle command line arguments
if [[ $# -gt 0 ]]; then
    parse_arguments "$@"
else
    main
fi
#!/bin/bash

# Portfolio Deployment Verification Script
# This script verifies all deployment components are working correctly

set -euo pipefail

# Configuration
SERVICE_NAME="portfolio"
SERVICE_USER="portfolio" 
SERVICE_GROUP="portfolio"
APP_DIR="/var/www/portfolio"
LOG_DIR="/var/log/portfolio"
SERVICE_FILE="portfolio.service"
PORT=3000
HEALTH_PORT=3001

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters for summary
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "${RED}✗ FAIL: $1${NC}"
    ((CHECKS_FAILED++))
}

success() {
    log "${GREEN}✓ PASS: $1${NC}"
    ((CHECKS_PASSED++))
}

warning() {
    log "${YELLOW}⚠ WARN: $1${NC}"
    ((CHECKS_WARNED++))
}

info() {
    log "${BLUE}ℹ INFO: $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Test HTTP endpoint
test_endpoint() {
    local url="$1"
    local expected_code="${2:-200}"
    local timeout="${3:-10}"
    
    if curl -f -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" | grep -q "$expected_code"; then
        return 0
    else
        return 1
    fi
}

# Check system prerequisites
check_prerequisites() {
    info "Checking system prerequisites..."
    
    # Check if running as root or with sudo
    if [[ $EUID -eq 0 ]]; then
        success "Running with root privileges"
    else
        warning "Not running as root - some checks may fail"
    fi
    
    # Check essential commands
    for cmd in systemctl curl node npm pm2; do
        if command_exists "$cmd"; then
            success "$cmd is installed"
        else
            error "$cmd is not installed or not in PATH"
        fi
    done
    
    # Check Node.js version
    if command_exists node; then
        NODE_VERSION=$(node --version)
        success "Node.js version: $NODE_VERSION"
    fi
    
    # Check PM2 version
    if command_exists pm2; then
        PM2_VERSION=$(pm2 --version)
        success "PM2 version: $PM2_VERSION"
    fi
}

# Check user and group
check_user_group() {
    info "Checking user and group configuration..."
    
    if getent group "$SERVICE_GROUP" > /dev/null 2>&1; then
        success "Group '$SERVICE_GROUP' exists"
    else
        error "Group '$SERVICE_GROUP' does not exist"
    fi
    
    if getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
        success "User '$SERVICE_USER' exists"
        
        # Check user's home directory
        USER_HOME=$(getent passwd "$SERVICE_USER" | cut -d: -f6)
        if [[ "$USER_HOME" == "$APP_DIR" ]]; then
            success "User home directory is correctly set to $APP_DIR"
        else
            warning "User home directory is $USER_HOME, expected $APP_DIR"
        fi
    else
        error "User '$SERVICE_USER' does not exist"
    fi
}

# Check directories and permissions
check_directories() {
    info "Checking directories and permissions..."
    
    # Check application directory
    if [[ -d "$APP_DIR" ]]; then
        success "Application directory exists: $APP_DIR"
        
        # Check ownership
        OWNER=$(stat -c %U:%G "$APP_DIR" 2>/dev/null || echo "unknown")
        if [[ "$OWNER" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
            success "Application directory has correct ownership ($OWNER)"
        else
            error "Application directory has incorrect ownership ($OWNER), expected $SERVICE_USER:$SERVICE_GROUP"
        fi
        
        # Check permissions
        PERMS=$(stat -c %a "$APP_DIR" 2>/dev/null || echo "unknown")
        if [[ "$PERMS" == "755" ]]; then
            success "Application directory has correct permissions ($PERMS)"
        else
            warning "Application directory permissions ($PERMS), recommended 755"
        fi
    else
        error "Application directory does not exist: $APP_DIR"
    fi
    
    # Check log directory
    if [[ -d "$LOG_DIR" ]]; then
        success "Log directory exists: $LOG_DIR"
    else
        error "Log directory does not exist: $LOG_DIR"
    fi
    
    # Check PM2 directory
    if [[ -d "$APP_DIR/.pm2" ]]; then
        success "PM2 directory exists: $APP_DIR/.pm2"
    else
        warning "PM2 directory does not exist: $APP_DIR/.pm2"
    fi
}

# Check application files
check_application_files() {
    info "Checking application files..."
    
    # Essential files
    local essential_files=(
        "$APP_DIR/package.json"
        "$APP_DIR/ecosystem.config.js"
        "$APP_DIR/dist/index.html"
    )
    
    for file in "${essential_files[@]}"; do
        if [[ -f "$file" ]]; then
            success "Essential file exists: $(basename "$file")"
        else
            error "Essential file missing: $file"
        fi
    done
    
    # Check node_modules
    if [[ -d "$APP_DIR/node_modules" ]]; then
        success "Node modules installed"
        
        # Check if node_modules is not empty
        if [[ -n "$(ls -A "$APP_DIR/node_modules" 2>/dev/null)" ]]; then
            success "Node modules directory is not empty"
        else
            error "Node modules directory is empty"
        fi
    else
        error "Node modules not installed in $APP_DIR"
    fi
    
    # Check dist directory
    if [[ -d "$APP_DIR/dist" ]]; then
        success "Build directory exists"
        
        # Check if dist has content
        if [[ -n "$(ls -A "$APP_DIR/dist" 2>/dev/null)" ]]; then
            success "Build directory contains files"
        else
            error "Build directory is empty"
        fi
    else
        error "Build directory does not exist"
    fi
}

# Check systemd service
check_systemd_service() {
    info "Checking systemd service..."
    
    # Check service file exists
    if [[ -f "/etc/systemd/system/$SERVICE_FILE" ]]; then
        success "Service file exists: /etc/systemd/system/$SERVICE_FILE"
    else
        error "Service file does not exist: /etc/systemd/system/$SERVICE_FILE"
        return 1
    fi
    
    # Check service is loaded
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        success "Service is loaded in systemd"
    else
        error "Service is not loaded in systemd"
    fi
    
    # Check service is enabled
    if systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        success "Service is enabled"
    else
        error "Service is not enabled"
    fi
    
    # Check service status
    if systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        success "Service is active/running"
    else
        error "Service is not active/running"
        
        # Show recent logs
        info "Recent service logs:"
        systemctl status "$SERVICE_NAME" --no-pager -l || true
    fi
    
    # Check service has no failed units
    FAILED_COUNT=$(systemctl --failed --quiet | wc -l)
    if [[ "$FAILED_COUNT" -eq 0 ]]; then
        success "No failed systemd units"
    else
        warning "$FAILED_COUNT failed systemd units detected"
    fi
}

# Check PM2 processes
check_pm2_processes() {
    info "Checking PM2 processes..."
    
    # Check PM2 as service user
    if sudo -u "$SERVICE_USER" pm2 list >/dev/null 2>&1; then
        success "PM2 is accessible for service user"
        
        # Get PM2 status
        PM2_OUTPUT=$(sudo -u "$SERVICE_USER" pm2 jlist 2>/dev/null || echo "[]")
        
        if [[ "$PM2_OUTPUT" != "[]" ]]; then
            success "PM2 processes are running"
            
            # Check specific process status
            if echo "$PM2_OUTPUT" | grep -q '"status":"online"'; then
                success "Portfolio process is online in PM2"
            else
                error "Portfolio process is not online in PM2"
            fi
        else
            error "No PM2 processes found"
        fi
        
    else
        error "Cannot access PM2 as service user"
    fi
}

# Check network connectivity
check_network() {
    info "Checking network connectivity..."
    
    # Check if ports are listening
    if netstat -tulpn 2>/dev/null | grep -q ":$PORT "; then
        success "Application port $PORT is listening"
    else
        error "Application port $PORT is not listening"
    fi
    
    if netstat -tulpn 2>/dev/null | grep -q ":$HEALTH_PORT "; then
        success "Health check port $HEALTH_PORT is listening"
    else
        warning "Health check port $HEALTH_PORT is not listening"
    fi
    
    # Test application endpoint
    if test_endpoint "http://localhost:$PORT/"; then
        success "Application responds on port $PORT"
    else
        error "Application does not respond on port $PORT"
    fi
    
    # Test health endpoint
    if test_endpoint "http://localhost:$HEALTH_PORT/health"; then
        success "Health endpoint responds on port $HEALTH_PORT"
    else
        warning "Health endpoint does not respond on port $HEALTH_PORT"
    fi
}

# Check nginx configuration
check_nginx() {
    info "Checking nginx configuration..."
    
    if command_exists nginx; then
        success "Nginx is installed"
        
        # Check nginx status
        if systemctl is-active nginx >/dev/null 2>&1; then
            success "Nginx is running"
        else
            warning "Nginx is not running"
        fi
        
        # Check nginx configuration
        if nginx -t >/dev/null 2>&1; then
            success "Nginx configuration is valid"
        else
            error "Nginx configuration has errors"
        fi
        
        # Check if nginx is listening on port 80
        if netstat -tulpn 2>/dev/null | grep -q ":80 "; then
            success "Nginx is listening on port 80"
        else
            warning "Nginx is not listening on port 80"
        fi
        
    else
        warning "Nginx is not installed"
    fi
}

# Check security configuration
check_security() {
    info "Checking security configuration..."
    
    # Check firewall status
    if command_exists ufw; then
        UFW_STATUS=$(ufw status | head -1)
        if echo "$UFW_STATUS" | grep -q "active"; then
            success "UFW firewall is active"
        else
            warning "UFW firewall is inactive"
        fi
    else
        warning "UFW firewall not installed"
    fi
    
    # Check sudoers file
    if [[ -f "/etc/sudoers.d/$SERVICE_NAME" ]]; then
        success "Sudoers configuration exists"
    else
        warning "Sudoers configuration not found"
    fi
    
    # Check log rotation
    if [[ -f "/etc/logrotate.d/$SERVICE_NAME" ]]; then
        success "Log rotation configured"
    else
        warning "Log rotation not configured"
    fi
}

# Check logs
check_logs() {
    info "Checking logs..."
    
    # Check systemd logs
    if journalctl -u "$SERVICE_NAME" --since "1 hour ago" | grep -q "ERROR\|FATAL"; then
        warning "Recent errors found in systemd logs"
    else
        success "No recent errors in systemd logs"
    fi
    
    # Check PM2 logs
    if sudo -u "$SERVICE_USER" pm2 logs --err --lines 50 2>/dev/null | grep -q "ERROR\|FATAL"; then
        warning "Recent errors found in PM2 logs"
    else
        success "No recent errors in PM2 logs"
    fi
    
    # Check disk space for logs
    LOG_USAGE=$(df "$LOG_DIR" | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    if [[ "$LOG_USAGE" -lt 80 ]]; then
        success "Log directory disk usage is acceptable ($LOG_USAGE%)"
    else
        warning "Log directory disk usage is high ($LOG_USAGE%)"
    fi
}

# Performance checks
check_performance() {
    info "Checking performance..."
    
    # Check memory usage
    if command_exists free; then
        MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        if (( $(echo "$MEMORY_USAGE < 80" | bc -l) )); then
            success "Memory usage is acceptable (${MEMORY_USAGE}%)"
        else
            warning "Memory usage is high (${MEMORY_USAGE}%)"
        fi
    fi
    
    # Check disk space
    DISK_USAGE=$(df "$APP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    if [[ "$DISK_USAGE" -lt 80 ]]; then
        success "Disk usage is acceptable ($DISK_USAGE%)"
    else
        warning "Disk usage is high ($DISK_USAGE%)"
    fi
    
    # Test response time
    if command_exists curl; then
        RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}\n' "http://localhost:$PORT/" 2>/dev/null || echo "999")
        if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
            success "Response time is good (${RESPONSE_TIME}s)"
        else
            warning "Response time is slow (${RESPONSE_TIME}s)"
        fi
    fi
}

# Generate summary report
generate_summary() {
    echo
    info "=== DEPLOYMENT VERIFICATION SUMMARY ==="
    echo
    
    local total_checks=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED))
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        success "✓ Deployment verification PASSED"
    else
        error "✗ Deployment verification FAILED"
    fi
    
    echo
    log "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
    log "Checks failed: ${RED}$CHECKS_FAILED${NC}"
    log "Warnings: ${YELLOW}$CHECKS_WARNED${NC}"
    log "Total checks: $total_checks"
    
    echo
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        info "Deployment has critical issues that need to be addressed."
        return 1
    elif [[ $CHECKS_WARNED -gt 0 ]]; then
        info "Deployment is functional but has some warnings."
        return 0
    else
        info "Deployment is fully operational!"
        return 0
    fi
}

# Main verification function
main() {
    info "Starting deployment verification..."
    echo
    
    check_prerequisites
    echo
    check_user_group
    echo
    check_directories
    echo
    check_application_files
    echo
    check_systemd_service
    echo
    check_pm2_processes
    echo
    check_network
    echo
    check_nginx
    echo
    check_security
    echo
    check_logs
    echo
    check_performance
    echo
    
    generate_summary
}

# Handle command line arguments
case "${1:-}" in
    --quick)
        info "Running quick verification..."
        check_systemd_service
        check_network
        generate_summary
        ;;
    --network)
        info "Running network checks only..."
        check_network
        generate_summary
        ;;
    --logs)
        info "Showing recent logs..."
        journalctl -u "$SERVICE_NAME" -n 50 --no-pager
        sudo -u "$SERVICE_USER" pm2 logs --lines 20 || true
        ;;
    --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --quick     Run only essential checks"
        echo "  --network   Run only network connectivity checks"
        echo "  --logs      Show recent logs"
        echo "  --help      Show this help message"
        ;;
    *)
        main "$@"
        ;;
esac
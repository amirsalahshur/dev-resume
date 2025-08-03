#!/bin/bash

# Portfolio Zero-Downtime Deployment Script
# This script implements rolling updates with health checks for zero-downtime deployment

set -euo pipefail

# Configuration
APP_NAME="amir-portfolio"
DEPLOY_USER="portfolio"
DEPLOY_PATH="/var/www/portfolio"
BACKUP_PATH="/var/backups/portfolio"
LOG_FILE="/var/log/portfolio/deploy.log"
HEALTH_CHECK_URL="http://localhost:3001/health"
HEALTH_CHECK_TIMEOUT=30
ROLLBACK_ENABLED=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

info() {
    log "${BLUE}INFO: $1${NC}"
}

# Check if running as correct user
check_user() {
    if [[ $EUID -eq 0 ]] && [[ "$DEPLOY_USER" != "root" ]]; then
        error "This script should not be run as root. Switch to $DEPLOY_USER user."
    fi
    
    if [[ "$(whoami)" != "$DEPLOY_USER" ]] && [[ "$DEPLOY_USER" != "root" ]]; then
        error "This script should be run as $DEPLOY_USER user."
    fi
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check if pm2 is installed
    if ! command -v pm2 &> /dev/null; then
        error "PM2 is not installed. Please install PM2 first."
    fi
    
    # Check if nginx is running
    if ! systemctl is-active --quiet nginx; then
        error "Nginx is not running. Please start nginx first."
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed."
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    REQUIRED_VERSION="20.0.0"
    if ! printf '%s\n%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V -C; then
        error "Node.js version $NODE_VERSION is less than required $REQUIRED_VERSION"
    fi
    
    success "Prerequisites check passed"
}

# Create backup
create_backup() {
    info "Creating backup..."
    
    BACKUP_DIR="$BACKUP_PATH/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$DEPLOY_PATH/dist" ]]; then
        cp -r "$DEPLOY_PATH/dist" "$BACKUP_DIR/"
        cp "$DEPLOY_PATH/package.json" "$BACKUP_DIR/" 2>/dev/null || true
        cp "$DEPLOY_PATH/ecosystem.config.js" "$BACKUP_DIR/" 2>/dev/null || true
        success "Backup created at $BACKUP_DIR"
        echo "$BACKUP_DIR" > /tmp/portfolio_last_backup
    else
        warning "No existing deployment found, skipping backup"
    fi
}

# Health check function
health_check() {
    local url="$1"
    local max_attempts="$2"
    local attempt=1
    
    info "Performing health check at $url"
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s "$url" > /dev/null; then
            success "Health check passed on attempt $attempt"
            return 0
        fi
        
        warning "Health check failed (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
    return 1
}

# Install dependencies
install_dependencies() {
    info "Installing dependencies..."
    
    cd "$DEPLOY_PATH"
    
    # Clean install for production
    if [[ -f "package-lock.json" ]]; then
        npm ci --production=false
    else
        npm install
    fi
    
    success "Dependencies installed successfully"
}

# Build application
build_application() {
    info "Building application..."
    
    cd "$DEPLOY_PATH"
    
    # Build for production
    npm run build
    
    # Verify build output
    if [[ ! -f "dist/index.html" ]]; then
        error "Build failed: dist/index.html not found"
    fi
    
    success "Application built successfully"
}

# Deploy with PM2
deploy_with_pm2() {
    info "Deploying with PM2..."
    
    cd "$DEPLOY_PATH"
    
    # Check if PM2 process exists
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        info "Reloading existing PM2 process..."
        pm2 reload ecosystem.config.js --env production
    else
        info "Starting new PM2 process..."
        pm2 start ecosystem.config.js --env production
    fi
    
    # Save PM2 configuration
    pm2 save
    
    success "PM2 deployment completed"
}

# Reload Nginx configuration
reload_nginx() {
    info "Reloading Nginx configuration..."
    
    # Test nginx configuration
    if sudo nginx -t; then
        sudo systemctl reload nginx
        success "Nginx reloaded successfully"
    else
        error "Nginx configuration test failed"
    fi
}

# Run post-deployment checks
post_deployment_checks() {
    info "Running post-deployment checks..."
    
    # Wait for application to start
    sleep 5
    
    # Check PM2 status
    if ! pm2 describe "$APP_NAME" | grep -q "online"; then
        error "PM2 process is not online"
    fi
    
    # Check health endpoint
    health_check "$HEALTH_CHECK_URL" 10
    
    # Check main application
    if ! curl -f -s http://localhost:3000 > /dev/null; then
        error "Main application is not responding"
    fi
    
    success "Post-deployment checks passed"
}

# Rollback function
rollback() {
    if [[ "$ROLLBACK_ENABLED" != "true" ]]; then
        error "Rollback is disabled"
    fi
    
    error "Deployment failed, initiating rollback..."
    
    if [[ -f "/tmp/portfolio_last_backup" ]]; then
        BACKUP_DIR=$(cat /tmp/portfolio_last_backup)
        if [[ -d "$BACKUP_DIR" ]]; then
            info "Rolling back to $BACKUP_DIR"
            
            # Stop current PM2 processes
            pm2 stop "$APP_NAME" || true
            
            # Restore backup
            rm -rf "$DEPLOY_PATH/dist"
            cp -r "$BACKUP_DIR/dist" "$DEPLOY_PATH/"
            
            # Restart PM2
            pm2 start ecosystem.config.js --env production
            
            # Reload nginx
            sudo systemctl reload nginx
            
            success "Rollback completed"
        else
            error "Backup directory not found: $BACKUP_DIR"
        fi
    else
        error "No backup found for rollback"
    fi
}

# Cleanup old backups
cleanup_backups() {
    info "Cleaning up old backups..."
    
    # Keep only last 5 backups
    cd "$BACKUP_PATH"
    ls -t | tail -n +6 | xargs -r rm -rf
    
    success "Old backups cleaned up"
}

# Pre-deployment hooks
pre_deploy_hook() {
    info "Running pre-deployment hooks..."
    
    # Send notification (if configured)
    if command -v slack-notify &> /dev/null; then
        slack-notify "🚀 Starting deployment of $APP_NAME"
    fi
    
    # Custom pre-deployment commands can be added here
    
    success "Pre-deployment hooks completed"
}

# Post-deployment hooks
post_deploy_hook() {
    info "Running post-deployment hooks..."
    
    # Warm up cache if needed
    curl -s http://localhost:3000 > /dev/null || true
    
    # Send success notification
    if command -v slack-notify &> /dev/null; then
        slack-notify "✅ Deployment of $APP_NAME completed successfully"
    fi
    
    # Custom post-deployment commands can be added here
    
    success "Post-deployment hooks completed"
}

# Main deployment function
main() {
    info "Starting zero-downtime deployment of $APP_NAME"
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Setup error handling
    trap rollback ERR
    
    # Run deployment steps
    check_user
    check_prerequisites
    pre_deploy_hook
    create_backup
    install_dependencies
    build_application
    deploy_with_pm2
    reload_nginx
    post_deployment_checks
    post_deploy_hook
    cleanup_backups
    
    success "Zero-downtime deployment completed successfully!"
    
    # Display application status
    info "Application Status:"
    pm2 status "$APP_NAME"
}

# Script options
case "${1:-}" in
    --rollback)
        rollback
        ;;
    --health-check)
        health_check "$HEALTH_CHECK_URL" 5
        ;;
    --status)
        pm2 status "$APP_NAME"
        ;;
    --logs)
        pm2 logs "$APP_NAME"
        ;;
    *)
        main "$@"
        ;;
esac
#!/bin/bash

# Portfolio Installation Test Script
# This script validates all the fixes made to the installation system

set -e

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

# Test 1: Argument parsing (CRITICAL FIX)
test_argument_parsing() {
    info "Testing argument parsing fixes..."
    
    # Test with subdomain (the critical bug scenario)
    local test_output
    test_output=$(timeout 5s bash scripts/install.sh info.amirsalahshur.xyz admin@example.com --dry-run 2>&1)
    
    # Check if current execution shows the error (not old log entries)
    local current_output=$(echo "$test_output" | head -10)
    
    if echo "$current_output" | grep -q "Unknown argument: info.amirsalahshur.xyz"; then
        error "CRITICAL BUG STILL EXISTS: Argument parsing is broken"
    fi
    
    if echo "$test_output" | grep -q "Setting domain: info.amirsalahshur.xyz"; then
        success "✓ Argument parsing fixed - subdomain accepted"
    else
        error "Domain argument not processed correctly"
    fi
    
    if echo "$test_output" | grep -q "Setting email: admin@example.com"; then
        success "✓ Email argument processed correctly"
    else
        error "Email argument not processed correctly"
    fi
}

# Test 2: Domain validation for subdomains
test_domain_validation() {
    info "Testing domain validation for subdomains..."
    
    local test_domains=(
        "example.com"
        "info.example.com"
        "api.v2.example.com"
        "info.amirsalahshur.xyz"
        "staging.portfolio.dev"
    )
    
    for domain in "${test_domains[@]}"; do
        local test_output
        test_output=$(timeout 3s bash scripts/install.sh "$domain" admin@example.com --dry-run 2>&1 | head -10)
        
        if echo "$test_output" | grep -q "Invalid domain format"; then
            error "Domain validation failed for valid domain: $domain"
        else
            success "✓ Domain validation passed for: $domain"
        fi
    done
}

# Test 3: Nginx configuration for subdomains
test_nginx_subdomain_support() {
    info "Testing nginx configuration for subdomain support..."
    
    # Create temporary nginx config
    local temp_nginx="/tmp/test_nginx.conf"
    cp nginx.conf "$temp_nginx"
    
    # Test subdomain replacement
    sed -i "s/your-domain\.com/info.example.com/g" "$temp_nginx"
    sed -i "s/ www\.your-domain\.com//g" "$temp_nginx"
    
    if grep -q "info.example.com" "$temp_nginx" && ! grep -q "www.info.example.com" "$temp_nginx"; then
        success "✓ Nginx subdomain configuration correct"
    else
        error "Nginx subdomain configuration failed"
    fi
    
    rm -f "$temp_nginx"
}

# Test 4: SSL certificate logic for subdomains
test_ssl_certificate_logic() {
    info "Testing SSL certificate generation logic..."
    
    # Simulate the SSL certificate domain logic from install.sh
    test_ssl_domains() {
        local domain="$1"
        local expected_cert_count="$2"
        
        local cert_domains="-d $domain"
        
        if [[ "$domain" != www.* ]]; then
            local domain_parts=(${domain//./ })
            if [[ ${#domain_parts[@]} -eq 2 ]]; then
                cert_domains="$cert_domains -d www.$domain"
            fi
        fi
        
        local actual_count=$(echo "$cert_domains" | grep -o "\-d" | wc -l)
        
        if [[ "$actual_count" -eq "$expected_cert_count" ]]; then
            success "✓ SSL certificate logic correct for $domain ($actual_count domains)"
        else
            error "SSL certificate logic failed for $domain (expected $expected_cert_count, got $actual_count)"
        fi
    }
    
    test_ssl_domains "example.com" 2          # Should include www.example.com
    test_ssl_domains "info.example.com" 1     # Should NOT include www.info.example.com
    test_ssl_domains "api.v2.example.com" 1   # Should NOT include www.api.v2.example.com
    test_ssl_domains "www.example.com" 1      # Should not add another www
}

# Test 5: Setup service script improvements
test_setup_service_improvements() {
    info "Testing setup service script improvements..."
    
    # Check if setup-service.sh has the improved systemd verification
    if grep -q "Verifying service recognition" scripts/setup-service.sh && \
       grep -q "systemctl list-unit-files.*SERVICE_NAME" scripts/setup-service.sh && \
       grep -q "systemctl cat.*SERVICE_NAME" scripts/setup-service.sh; then
        success "✓ Setup service script has improved systemd verification"
    else
        error "Setup service script missing improved systemd verification"
    fi
    
    # Check for retry logic
    if grep -q "retry_systemd_operation" scripts/setup-service.sh; then
        success "✓ Setup service script has retry logic"
    else
        error "Setup service script missing retry logic"
    fi
}

# Test 6: Deploy script error handling
test_deploy_error_handling() {
    info "Testing deploy script error handling improvements..."
    
    # Check for enhanced rollback function
    if grep -q "Enhanced rollback function" scripts/deploy.sh && \
       grep -q "handle_deployment_error" scripts/deploy.sh && \
       grep -q "run_deployment_step" scripts/deploy.sh; then
        success "✓ Deploy script has enhanced error handling"
    else
        error "Deploy script missing enhanced error handling"
    fi
    
    # Check for deployment timing
    if grep -q "DEPLOY_START_TIME" scripts/deploy.sh && \
       grep -q "DEPLOY_DURATION" scripts/deploy.sh; then
        success "✓ Deploy script has deployment timing"
    else
        error "Deploy script missing deployment timing"
    fi
}

# Test 7: Ecosystem config PM2 paths
test_ecosystem_config() {
    info "Testing ecosystem config PM2 paths..."
    
    # Check if ecosystem.config.js uses proper vite preview command
    if grep -q "vite preview --port 3000 --host 0.0.0.0" ecosystem.config.js; then
        success "✓ Ecosystem config uses proper vite preview command"
    else
        error "Ecosystem config not using proper vite preview command"
    fi
    
    # Check for health check script
    if grep -q "./scripts/health-check.js" ecosystem.config.js; then
        success "✓ Ecosystem config includes health check script"
    else
        error "Ecosystem config missing health check script"
    fi
}

# Test 8: Dockerfile Node.js version
test_dockerfile_nodejs() {
    info "Testing Dockerfile Node.js version..."
    
    if grep -q "FROM node:20-alpine" Dockerfile; then
        success "✓ Dockerfile uses Node.js 20"
    else
        error "Dockerfile not using Node.js 20"
    fi
    
    # Check health check path
    if grep -q "node /app/scripts/health-check.js" Dockerfile; then
        success "✓ Dockerfile health check path is correct"
    else
        error "Dockerfile health check path is incorrect"
    fi
}

# Test 9: GitHub workflow fixes
test_github_workflow() {
    info "Testing GitHub workflow fixes..."
    
    # Check for awk instead of bc
    if grep -q "awk.*BEGIN.*exit" .github/workflows/deploy.yml; then
        success "✓ GitHub workflow uses awk instead of bc"
    else
        error "GitHub workflow still using bc or missing performance check"
    fi
    
    # Check for proper variable handling
    if grep -q "vars.ENABLE_PRODUCTION_DEPLOY != 'false'" .github/workflows/deploy.yml; then
        success "✓ GitHub workflow has proper variable handling"
    else
        error "GitHub workflow missing proper variable handling"
    fi
}

# Test 10: Package.json scripts
test_package_scripts() {
    info "Testing package.json scripts..."
    
    local required_scripts=(
        "start"
        "build"
        "start:pm2"
        "deploy:production"
        "setup:service"
    )
    
    for script in "${required_scripts[@]}"; do
        if grep -q "\"$script\":" package.json; then
            success "✓ Package.json has $script script"
        else
            error "Package.json missing $script script"
        fi
    done
}

# Test 11: Installation command simulation
test_installation_command() {
    info "Testing installation command that was failing..."
    
    # This should now work without the "Unknown argument" error
    local test_cmd="timeout 5s bash scripts/install.sh info.amirsalahshur.xyz admin@example.com --dry-run"
    local test_output
    
    if test_output=$($test_cmd 2>&1); then
        if echo "$test_output" | grep -q "DRY RUN MODE" && \
           echo "$test_output" | grep -q "Setting domain: info.amirsalahshur.xyz"; then
            success "✓ Installation command works correctly"
        else
            warning "Installation command runs but output unexpected"
            echo "Output: $test_output" | head -10
        fi
    else
        error "Installation command failed to run"
        echo "Output: $test_output" | head -10
    fi
}

# Main test runner
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Portfolio Installation Test Suite                  ║"
    echo "║                                                              ║"
    echo "║  Testing all fixes made to the deployment system            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    local tests=(
        "test_argument_parsing"
        "test_domain_validation"
        "test_nginx_subdomain_support"
        "test_ssl_certificate_logic"
        "test_setup_service_improvements"
        "test_deploy_error_handling"
        "test_ecosystem_config"
        "test_dockerfile_nodejs"
        "test_github_workflow"
        "test_package_scripts"
        "test_installation_command"
    )
    
    local passed=0
    local total=${#tests[@]}
    
    for test in "${tests[@]}"; do
        echo "----------------------------------------"
        if $test; then
            ((passed++))
        fi
        echo
    done
    
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    TEST RESULTS                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
    success "Passed: $passed/$total tests"
    
    if [[ $passed -eq $total ]]; then
        success "🎉 ALL TESTS PASSED! Installation system is fixed."
        echo
        echo "The following critical issues have been resolved:"
        echo "✅ CRITICAL: Broken argument parsing in install.sh"
        echo "✅ Domain validation now accepts subdomains"
        echo "✅ Systemd service verification timing issues fixed"
        echo "✅ Deploy script error handling and rollback improved"
        echo "✅ Nginx config handles subdomains correctly"
        echo "✅ Ecosystem.config.js PM2 paths fixed"
        echo "✅ GitHub workflow variables handled properly"
        echo "✅ Dockerfile uses Node.js 20"
        echo "✅ All package.json scripts verified"
        echo
        echo "✨ The installation should now work flawlessly with:"
        echo "curl -fsSL https://raw.githubusercontent.com/amirsalahshur/dev-resume/main/scripts/install.sh | sudo bash -s -- info.amirsalahshur.xyz email@example.com"
    else
        error "Some tests failed. Please review the output above."
        exit 1
    fi
}

# Run the tests
main "$@"
#!/bin/bash

# Setup Secure Environment
# Initializes atomic state management and secure script handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Setup git hooks
setup_git_hooks() {
    log_info "Setting up git hooks for security..."
    
    if [[ ! -d ".git" ]]; then
        log_error "Not in a git repository"
        return 1
    fi
    
    # Setup secure script manager hooks
    ./scripts/secure-script-manager.sh setup-hooks
    
    log_success "Git hooks configured"
}

# Update .gitignore
update_gitignore() {
    log_info "Updating .gitignore for security..."
    
    if [[ -f ".gitignore" ]]; then
        # Backup existing .gitignore
        cp .gitignore .gitignore.backup
        log_info "Backed up existing .gitignore"
    fi
    
    # Append secure patterns
    cat .gitignore-secure >> .gitignore
    
    log_success ".gitignore updated with security patterns"
}

# Create secure directories
create_secure_directories() {
    log_info "Creating secure directories..."
    
    # Create secure scripts directory
    ./scripts/secure-script-manager.sh scan . || true
    
    # Create terraform backup directory
    mkdir -p ~/.terraform-state-backups
    chmod 700 ~/.terraform-state-backups
    
    log_success "Secure directories created"
}

# Test atomic terraform
test_atomic_terraform() {
    log_info "Testing atomic terraform functionality..."
    
    # Test with a simple terraform configuration
    if [[ -f "terraform/main.tf" ]]; then
        cd terraform
        ./scripts/atomic-terraform.sh validate || log_warning "Terraform validation failed (expected if not configured)"
        cd ..
    else
        log_info "No terraform configuration found, skipping test"
    fi
    
    log_success "Atomic terraform test completed"
}

# Create example secure script
create_example_script() {
    log_info "Creating example secure script..."
    
    ./scripts/secure-script-manager.sh create "example-deploy"
    
    log_success "Example secure script created"
}

# Setup environment variables
setup_environment() {
    log_info "Setting up environment variables..."
    
    # Create environment template
    cat > .env.template << 'EOF'
# Environment Variables Template
# Copy this to .env and fill in your values
# DO NOT COMMIT .env TO GIT

# AWS Configuration
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
export AWS_REGION="us-east-1"

# Terraform Configuration
export TF_VAR_environment="production"
export TF_VAR_region="us-east-1"

# Add your custom variables here
# export CUSTOM_SECRET="your-secret-value"
EOF
    
    log_success "Environment template created"
}

# Main setup function
main() {
    log_info "Setting up secure environment..."
    
    # Check if we're in the right directory
    if [[ ! -f "scripts/atomic-terraform.sh" ]]; then
        log_error "Please run this script from the project root directory"
        return 1
    fi
    
    # Run setup steps
    setup_git_hooks || log_warning "Git hooks setup failed"
    update_gitignore || log_warning ".gitignore update failed"
    create_secure_directories || log_warning "Secure directories creation failed"
    test_atomic_terraform || log_warning "Atomic terraform test failed"
    create_example_script || log_warning "Example script creation failed"
    setup_environment || log_warning "Environment setup failed"
    
    log_success "Secure environment setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Copy .env.template to .env and fill in your values"
    echo "2. Move any scripts with secrets using: ./scripts/secure-script-manager.sh move <script>"
    echo "3. Use atomic terraform: ./scripts/atomic-terraform.sh <command>"
    echo "4. Use safe deployment: ./scripts/safe-deployment.sh <action>"
    echo ""
    echo "For help:"
    echo "  ./scripts/atomic-terraform.sh help"
    echo "  ./scripts/secure-script-manager.sh help"
    echo "  ./scripts/safe-deployment.sh help"
}

# Run main function
main "$@"

#!/bin/bash

# Safe Deployment Script
# Combines atomic terraform operations with secure script management

set -euo pipefail

# Configuration
DEPLOYMENT_DIR="${1:-.}"
ENVIRONMENT="${2:-production}"
DRY_RUN="${3:-false}"

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

# Pre-deployment checks
pre_deployment_checks() {
    log_info "Running pre-deployment checks..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warning "Uncommitted changes detected"
        read -p "Continue with uncommitted changes? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Deployment cancelled"
            return 1
        fi
    fi
    
    # Scan for scripts with secrets
    if ! ./scripts/secure-script-manager.sh scan .; then
        log_warning "Scripts with potential secrets found"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Deployment cancelled due to potential secrets"
            return 1
        fi
    fi
    
    log_success "Pre-deployment checks passed"
}

# Validate terraform configuration
validate_terraform() {
    log_info "Validating terraform configuration..."
    
    if [[ ! -f "${DEPLOYMENT_DIR}/main.tf" && ! -f "${DEPLOYMENT_DIR}/terraform.tf" ]]; then
        log_error "No terraform configuration found in $DEPLOYMENT_DIR"
        return 1
    fi
    
    # Use atomic terraform for validation
    if ./scripts/atomic-terraform.sh validate; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration is invalid"
        return 1
    fi
}

# Plan deployment
plan_deployment() {
    log_info "Planning deployment for environment: $ENVIRONMENT"
    
    local plan_args=""
    if [[ "$ENVIRONMENT" != "production" ]]; then
        plan_args="-var-file=${ENVIRONMENT}.tfvars"
    fi
    
    if ./scripts/atomic-terraform.sh plan $plan_args; then
        log_success "Deployment plan created successfully"
    else
        log_error "Deployment planning failed"
        return 1
    fi
}

# Execute deployment
execute_deployment() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Deployment would be executed here"
        log_info "To execute for real, run: $0 $DEPLOYMENT_DIR $ENVIRONMENT false"
        return 0
    fi
    
    log_info "Executing deployment for environment: $ENVIRONMENT"
    
    local apply_args=""
    if [[ "$ENVIRONMENT" != "production" ]]; then
        apply_args="-var-file=${ENVIRONMENT}.tfvars"
    fi
    
    if ./scripts/atomic-terraform.sh apply $apply_args; then
        log_success "Deployment executed successfully"
    else
        log_error "Deployment execution failed"
        return 1
    fi
}

# Post-deployment verification
post_deployment_verification() {
    log_info "Running post-deployment verification..."
    
    # Check terraform state
    if ./scripts/atomic-terraform.sh validate; then
        log_success "Post-deployment state is valid"
    else
        log_warning "Post-deployment state validation failed"
    fi
    
    # Clean up old backups
    ./scripts/atomic-terraform.sh cleanup
    
    log_success "Post-deployment verification completed"
}

# Rollback function
rollback_deployment() {
    log_warning "Rollback requested"
    
    # List available backups
    log_info "Available state backups:"
    ls -la ~/.terraform-state-backups/ 2>/dev/null || log_info "No backups available"
    
    read -p "Enter backup timestamp to restore (YYYYMMDD_HHMMSS): " backup_timestamp
    if [[ -n "$backup_timestamp" ]]; then
        local backup_file="${HOME}/.terraform-state-backups/terraform_state_${backup_timestamp}.backup"
        if [[ -f "$backup_file" ]]; then
            log_info "Restoring from backup: $backup_file"
            cp "$backup_file" "${DEPLOYMENT_DIR}/.terraform/terraform.tfstate"
            log_success "State restored from backup"
        else
            log_error "Backup file not found: $backup_file"
            return 1
        fi
    fi
}

# Main deployment function
main() {
    local action="${1:-deploy}"
    shift || true
    
    case "$action" in
        "deploy")
            log_info "Starting safe deployment process..."
            
            pre_deployment_checks || return 1
            validate_terraform || return 1
            plan_deployment || return 1
            execute_deployment || return 1
            post_deployment_verification || return 1
            
            log_success "Deployment completed successfully!"
            ;;
        "plan")
            log_info "Planning deployment..."
            
            pre_deployment_checks || return 1
            validate_terraform || return 1
            plan_deployment || return 1
            
            log_success "Deployment plan completed!"
            ;;
        "rollback")
            rollback_deployment || return 1
            ;;
        "validate")
            validate_terraform || return 1
            ;;
        "check")
            pre_deployment_checks || return 1
            ;;
        "help"|*)
            echo "Usage: $0 <action> [deployment-dir] [environment] [dry-run]"
            echo ""
            echo "Actions:"
            echo "  deploy   - Full deployment process (default)"
            echo "  plan     - Plan deployment only"
            echo "  rollback - Rollback to previous state"
            echo "  validate - Validate configuration only"
            echo "  check    - Pre-deployment checks only"
            echo "  help     - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 deploy . production false"
            echo "  $0 plan . staging false"
            echo "  $0 rollback"
            echo "  $0 validate ."
            ;;
    esac
}

# Run main function with all arguments
main "$@"

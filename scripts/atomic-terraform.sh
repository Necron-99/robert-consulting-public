#!/bin/bash

# Atomic Terraform State Management
# Prevents corruption from network issues and provides safe operations

set -euo pipefail

# Configuration
TERRAFORM_DIR="${1:-.}"
STATE_BACKUP_DIR="${HOME}/.terraform-state-backups"
LOCK_TIMEOUT=300  # 5 minutes
RETRY_ATTEMPTS=3
RETRY_DELAY=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Create backup directory
create_backup_dir() {
    if [[ ! -d "$STATE_BACKUP_DIR" ]]; then
        mkdir -p "$STATE_BACKUP_DIR"
        log_info "Created backup directory: $STATE_BACKUP_DIR"
    fi
}

# Backup current state
backup_state() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${STATE_BACKUP_DIR}/terraform_state_${timestamp}.backup"
    
    if [[ -f "${TERRAFORM_DIR}/.terraform/terraform.tfstate" ]]; then
        cp "${TERRAFORM_DIR}/.terraform/terraform.tfstate" "$backup_file"
        log_success "State backed up to: $backup_file"
        echo "$backup_file"
    else
        log_warning "No state file found to backup"
        echo ""
    fi
}

# Atomic operation wrapper
atomic_operation() {
    local operation="$1"
    shift
    local args="$@"
    
    log_info "Starting atomic operation: $operation"
    
    # Create backup before operation
    local backup_file=$(backup_state)
    
    # Set up retry mechanism
    local attempt=1
    while [[ $attempt -le $RETRY_ATTEMPTS ]]; do
        log_info "Attempt $attempt of $RETRY_ATTEMPTS"
        
        # Try the operation with timeout
        if timeout $LOCK_TIMEOUT terraform -chdir="$TERRAFORM_DIR" $operation $args; then
            log_success "Operation '$operation' completed successfully"
            return 0
        else
            local exit_code=$?
            log_warning "Operation failed with exit code: $exit_code"
            
            if [[ $attempt -lt $RETRY_ATTEMPTS ]]; then
                log_info "Waiting $RETRY_DELAY seconds before retry..."
                sleep $RETRY_DELAY
                
                # Restore from backup if available
                if [[ -n "$backup_file" && -f "$backup_file" ]]; then
                    log_info "Restoring state from backup..."
                    cp "$backup_file" "${TERRAFORM_DIR}/.terraform/terraform.tfstate"
                fi
            fi
        fi
        
        ((attempt++))
    done
    
    log_error "Operation '$operation' failed after $RETRY_ATTEMPTS attempts"
    return 1
}

# Safe terraform init
safe_init() {
    log_info "Performing safe terraform init..."
    atomic_operation "init" "-upgrade"
}

# Safe terraform plan
safe_plan() {
    log_info "Performing safe terraform plan..."
    atomic_operation "plan" "-detailed-exitcode" "-out=plan.tfplan"
}

# Safe terraform apply
safe_apply() {
    log_info "Performing safe terraform apply..."
    
    if [[ -f "plan.tfplan" ]]; then
        atomic_operation "apply" "plan.tfplan"
        rm -f plan.tfplan
    else
        log_warning "No plan file found, applying without plan..."
        atomic_operation "apply" "-auto-approve"
    fi
}

# Safe terraform destroy
safe_destroy() {
    log_info "Performing safe terraform destroy..."
    atomic_operation "destroy" "-auto-approve"
}

# State validation
validate_state() {
    log_info "Validating terraform state..."
    
    if terraform -chdir="$TERRAFORM_DIR" validate; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration is invalid"
        return 1
    fi
    
    if terraform -chdir="$TERRAFORM_DIR" plan -detailed-exitcode >/dev/null 2>&1; then
        log_success "State is consistent"
    else
        log_warning "State may be inconsistent - consider running plan"
    fi
}

# Cleanup old backups (keep last 10)
cleanup_backups() {
    log_info "Cleaning up old state backups..."
    
    if [[ -d "$STATE_BACKUP_DIR" ]]; then
        # Keep only the last 10 backups
        ls -t "$STATE_BACKUP_DIR"/*.backup 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
        log_success "Old backups cleaned up"
    fi
}

# Main function
main() {
    local command="${1:-help}"
    shift || true
    
    create_backup_dir
    
    case "$command" in
        "init")
            safe_init
            ;;
        "plan")
            safe_plan
            ;;
        "apply")
            safe_apply
            ;;
        "destroy")
            safe_destroy
            ;;
        "validate")
            validate_state
            ;;
        "backup")
            backup_state
            ;;
        "cleanup")
            cleanup_backups
            ;;
        "help"|*)
            echo "Usage: $0 <command> [terraform-args]"
            echo ""
            echo "Commands:"
            echo "  init     - Safe terraform init with retry"
            echo "  plan     - Safe terraform plan with backup"
            echo "  apply    - Safe terraform apply with backup"
            echo "  destroy  - Safe terraform destroy with backup"
            echo "  validate - Validate configuration and state"
            echo "  backup   - Create state backup"
            echo "  cleanup  - Clean up old backups"
            echo "  help     - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 plan -var-file=production.tfvars"
            echo "  $0 apply"
            echo "  $0 validate"
            ;;
    esac
}

# Run main function with all arguments
main "$@"

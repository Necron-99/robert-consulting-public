#!/bin/bash

# Migrate to Secure Backend Configuration
# Safely transition to production-ready Terraform state management

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

# Configuration
BACKUP_DIR="${HOME}/.terraform-state-backups"
MIGRATION_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup current state
backup_current_state() {
    log_info "Creating backup of current state..."
    
    local backup_file="${BACKUP_DIR}/terraform_state_${MIGRATION_TIMESTAMP}.backup"
    
    if [[ -f "terraform.tfstate" ]]; then
        cp terraform.tfstate "$backup_file"
        log_success "State backed up to: $backup_file"
    else
        log_warning "No local state file found"
    fi
    
    # Also backup from S3 if it exists
    if aws s3 ls s3://robert-consulting-terraform-state/terraform.tfstate >/dev/null 2>&1; then
        aws s3 cp s3://robert-consulting-terraform-state/terraform.tfstate "${backup_file}.s3"
        log_success "S3 state backed up to: ${backup_file}.s3"
    fi
}

# Initialize new backend configuration
init_new_backend() {
    log_info "Initializing new secure backend configuration..."
    
    # Remove old backend configuration
    if [[ -f "backend.tf" ]]; then
        mv backend.tf backend.tf.old
        log_info "Moved old backend.tf to backend.tf.old"
    fi
    
    # Use new secure backend configuration
    if [[ -f "backend-secure.tf" ]]; then
        log_info "Using backend-secure.tf configuration"
    else
        log_error "backend-secure.tf not found!"
        return 1
    fi
    
    # Initialize with migration
    if terraform init -migrate-state; then
        log_success "Backend migration completed successfully"
    else
        log_error "Backend migration failed"
        return 1
    fi
}

# Validate new configuration
validate_configuration() {
    log_info "Validating new configuration..."
    
    if terraform validate; then
        log_success "Configuration is valid"
    else
        log_error "Configuration validation failed"
        return 1
    fi
    
    if terraform plan -detailed-exitcode >/dev/null 2>&1; then
        log_success "Plan validation passed"
    else
        log_warning "Plan shows changes - this is expected during migration"
    fi
}

# Test state operations
test_state_operations() {
    log_info "Testing state operations..."
    
    # Test state list
    if terraform state list >/dev/null 2>&1; then
        log_success "State list operation successful"
    else
        log_error "State list operation failed"
        return 1
    fi
    
    # Test state show
    if terraform state show data.aws_caller_identity.current >/dev/null 2>&1; then
        log_success "State show operation successful"
    else
        log_warning "State show operation failed (may be expected)"
    fi
}

# Create rollback script
create_rollback_script() {
    log_info "Creating rollback script..."
    
    cat > rollback-migration.sh << EOF
#!/bin/bash
# Rollback script for Terraform backend migration
# Created: $(date)

set -euo pipefail

echo "🔄 Rolling back Terraform backend migration..."

# Restore old backend configuration
if [[ -f "backend.tf.old" ]]; then
    mv backend.tf.old backend.tf
    echo "✅ Restored old backend.tf"
fi

# Restore state from backup
if [[ -f "${BACKUP_DIR}/terraform_state_${MIGRATION_TIMESTAMP}.backup" ]]; then
    cp "${BACKUP_DIR}/terraform_state_${MIGRATION_TIMESTAMP}.backup" terraform.tfstate
    echo "✅ Restored state from backup"
fi

# Reinitialize with old configuration
terraform init -migrate-state

echo "✅ Rollback completed"
EOF
    
    chmod +x rollback-migration.sh
    log_success "Rollback script created: rollback-migration.sh"
}

# Main migration function
main() {
    local action="${1:-migrate}"
    
    case "$action" in
        "migrate")
            log_info "Starting secure backend migration..."
            
            create_backup_dir || return 1
            backup_current_state || return 1
            init_new_backend || return 1
            validate_configuration || return 1
            test_state_operations || return 1
            create_rollback_script || return 1
            
            log_success "Migration completed successfully!"
            echo ""
            echo "Next steps:"
            echo "1. Test your infrastructure: terraform plan"
            echo "2. Apply changes if needed: terraform apply"
            echo "3. If issues occur, run: ./rollback-migration.sh"
            echo ""
            echo "Backup location: $BACKUP_DIR"
            ;;
        "rollback")
            log_info "Rolling back migration..."
            ./rollback-migration.sh
            ;;
        "backup")
            log_info "Creating backup only..."
            create_backup_dir
            backup_current_state
            ;;
        "validate")
            log_info "Validating configuration..."
            validate_configuration
            ;;
        "help"|*)
            echo "Usage: $0 <action>"
            echo ""
            echo "Actions:"
            echo "  migrate  - Perform full migration to secure backend (default)"
            echo "  rollback - Rollback to previous configuration"
            echo "  backup   - Create backup only"
            echo "  validate - Validate configuration only"
            echo "  help     - Show this help"
            ;;
    esac
}

# Run main function
main "$@"

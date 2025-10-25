#!/bin/bash

# Terraform State Lock Manager
# Comprehensive solution for state lock issues following best practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TABLE="robert-consulting-terraform-locks"
REGION="us-east-1"
BUCKET="robert-consulting-terraform-state"
KEY="org/production/us-east-1/main-infrastructure.tfstate"

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

# Show all current locks
show_locks() {
    log_info "Checking for active locks in DynamoDB table: $TABLE"
    
    aws dynamodb scan \
        --table-name "$TABLE" \
        --region "$REGION" \
        --projection-expression "LockID, Info, Operation, Who, Created" \
        --query 'Items[*].{LockID:LockID.S, Who:Who.S, Operation:Operation.S, Created:Created.S, Info:Info.S}' \
        --output table 2>/dev/null || {
        log_error "Failed to scan DynamoDB table. Check if table exists and you have permissions."
        return 1
    }
}

# Check for specific lock
check_lock() {
    local lock_id="${BUCKET}/${KEY}"
    
    log_info "Checking for specific lock: $lock_id"
    
    aws dynamodb get-item \
        --region "$REGION" \
        --table-name "$TABLE" \
        --key "{\"LockID\": {\"S\": \"$lock_id\"}}" \
        --query 'Item' \
        --output json 2>/dev/null || {
        log_info "No lock found for $lock_id"
        return 0
    }
}

# Force unlock using Terraform
terraform_force_unlock() {
    local lock_id="$1"
    
    log_info "Attempting Terraform force unlock for: $lock_id"
    
    if terraform force-unlock -force "$lock_id"; then
        log_success "Successfully unlocked with Terraform"
        return 0
    else
        log_warning "Terraform force unlock failed"
        return 1
    fi
}

# DynamoDB cleanup (last resort)
dynamodb_cleanup() {
    local lock_id="${BUCKET}/${KEY}"
    
    log_warning "Performing DynamoDB cleanup for: $lock_id"
    log_warning "⚠️  Only proceed if you're 100% sure no apply is running!"
    
    read -p "Are you sure? Type 'yes' to continue: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Cleanup cancelled"
        return 1
    fi
    
    # Get the lock item first
    log_info "Retrieving lock item..."
    aws dynamodb get-item \
        --region "$REGION" \
        --table-name "$TABLE" \
        --key "{\"LockID\": {\"S\": \"$lock_id\"}}" \
        --output json
    
    # Delete the lock item
    log_info "Deleting lock item..."
    if aws dynamodb delete-item \
        --region "$REGION" \
        --table-name "$TABLE" \
        --key "{\"LockID\": {\"S\": \"$lock_id\"}}"; then
        log_success "Lock item deleted successfully"
        return 0
    else
        log_error "Failed to delete lock item"
        return 1
    fi
}

# Test backend configuration
test_backend() {
    log_info "Testing backend configuration..."
    
    # Test S3 bucket access
    if aws s3 ls "s3://$BUCKET" >/dev/null 2>&1; then
        log_success "S3 bucket accessible: $BUCKET"
    else
        log_error "S3 bucket not accessible: $BUCKET"
        return 1
    fi
    
    # Test DynamoDB table
    if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
        log_success "DynamoDB table accessible: $TABLE"
    else
        log_error "DynamoDB table not accessible: $TABLE"
        return 1
    fi
    
    # Test IAM permissions
    log_info "Testing IAM permissions..."
    if aws dynamodb put-item \
        --table-name "$TABLE" \
        --region "$REGION" \
        --item '{"LockID":{"S":"test-lock"},"Info":{"S":"test"}}' \
        --condition-expression "attribute_not_exists(LockID)" >/dev/null 2>&1; then
        log_success "DynamoDB write permissions OK"
        # Clean up test item
        aws dynamodb delete-item \
            --table-name "$TABLE" \
            --region "$REGION" \
            --key '{"LockID":{"S":"test-lock"}}' >/dev/null 2>&1 || true
    else
        log_warning "DynamoDB write permissions may be limited"
    fi
}

# Initialize with proper timeout
init_with_timeout() {
    local timeout="${1:-10m}"
    
    log_info "Initializing Terraform with lock timeout: $timeout"
    
    if terraform init -lock-timeout="$timeout"; then
        log_success "Terraform initialized successfully"
        return 0
    else
        log_error "Terraform initialization failed"
        return 1
    fi
}

# Plan with timeout
plan_with_timeout() {
    local timeout="${1:-10m}"
    
    log_info "Running Terraform plan with lock timeout: $timeout"
    
    if terraform plan -lock-timeout="$timeout"; then
        log_success "Terraform plan completed successfully"
        return 0
    else
        log_error "Terraform plan failed"
        return 1
    fi
}

# Apply with timeout
apply_with_timeout() {
    local timeout="${1:-10m}"
    
    log_info "Running Terraform apply with lock timeout: $timeout"
    
    if terraform apply -lock-timeout="$timeout"; then
        log_success "Terraform apply completed successfully"
        return 0
    else
        log_error "Terraform apply failed"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-help}"
    
    case "$action" in
        "show-locks")
            show_locks
            ;;
        "check-lock")
            check_lock
            ;;
        "force-unlock")
            local lock_id="${2:-}"
            if [[ -z "$lock_id" ]]; then
                log_error "Please provide LOCK_ID as second argument"
                exit 1
            fi
            terraform_force_unlock "$lock_id"
            ;;
        "dynamodb-cleanup")
            dynamodb_cleanup
            ;;
        "test-backend")
            test_backend
            ;;
        "init")
            local timeout="${2:-10m}"
            init_with_timeout "$timeout"
            ;;
        "plan")
            local timeout="${2:-10m}"
            plan_with_timeout "$timeout"
            ;;
        "apply")
            local timeout="${2:-10m}"
            apply_with_timeout "$timeout"
            ;;
        "help"|*)
            echo "Terraform State Lock Manager"
            echo ""
            echo "Usage: $0 <action> [args...]"
            echo ""
            echo "Actions:"
            echo "  show-locks           - Show all current locks"
            echo "  check-lock           - Check for specific lock"
            echo "  force-unlock <id>    - Force unlock using Terraform"
            echo "  dynamodb-cleanup     - Clean up lock in DynamoDB (last resort)"
            echo "  test-backend         - Test backend configuration"
            echo "  init [timeout]       - Initialize with lock timeout (default: 10m)"
            echo "  plan [timeout]       - Plan with lock timeout (default: 10m)"
            echo "  apply [timeout]      - Apply with lock timeout (default: 10m)"
            echo "  help                 - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 show-locks"
            echo "  $0 force-unlock robert-consulting-terraform-state/org/production/us-east-1/main-infrastructure.tfstate"
            echo "  $0 init 5m"
            echo "  $0 plan 15m"
            ;;
    esac
}

# Run main function
main "$@"

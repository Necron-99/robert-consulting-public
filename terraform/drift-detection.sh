#!/bin/bash

# Terraform State Drift Detection Script
# Ensures infrastructure matches Terraform state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    log_success "Terraform found: $(terraform version -json | jq -r '.terraform_version')"
}

# Check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
    
    log_success "AWS CLI configured for: $(aws sts get-caller-identity --query 'Account' --output text)"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    terraform init -upgrade
    log_success "Terraform initialized"
}

# Check for state drift
check_drift() {
    log_info "Checking for infrastructure drift..."
    
    # Run terraform plan to detect changes
    if terraform plan -detailed-exitcode -out=tfplan; then
        log_success "No drift detected - infrastructure matches state"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            log_error "Drift detected - infrastructure differs from state"
            log_info "Run 'terraform plan' to see detailed changes"
            return 1
        else
            log_error "Terraform plan failed with exit code $exit_code"
            return 1
        fi
    fi
}

# Validate Terraform configuration
validate_config() {
    log_info "Validating Terraform configuration..."
    if terraform validate; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration validation failed"
        exit 1
    fi
}

# Check state file integrity
check_state_integrity() {
    log_info "Checking state file integrity..."
    
    if terraform show -json > /dev/null 2>&1; then
        log_success "State file is valid and readable"
    else
        log_error "State file is corrupted or invalid"
        exit 1
    fi
}

# Generate drift report
generate_drift_report() {
    local report_file="drift-report-$(date +%Y%m%d-%H%M%S).txt"
    
    log_info "Generating drift report: $report_file"
    
    {
        echo "Terraform Drift Detection Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        echo "Terraform Version:"
        terraform version
        echo ""
        echo "AWS Account:"
        aws sts get-caller-identity
        echo ""
        echo "Current State Summary:"
        terraform show -json | jq -r '.values.root_module.resources[] | "\(.type).\(.name): \(.values.id // "N/A")"'
        echo ""
        echo "Planned Changes:"
        terraform plan -detailed-exitcode
    } > "$report_file"
    
    log_success "Drift report saved to: $report_file"
}

# Main drift detection workflow
main() {
    log_info "Starting Terraform drift detection..."
    
    check_terraform
    check_aws_cli
    init_terraform
    validate_config
    check_state_integrity
    
    if check_drift; then
        log_success "✅ No infrastructure drift detected"
        exit 0
    else
        log_error "❌ Infrastructure drift detected"
        generate_drift_report
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "check")
        main
        ;;
    "report")
        generate_drift_report
        ;;
    "validate")
        check_terraform
        check_aws_cli
        init_terraform
        validate_config
        check_state_integrity
        ;;
    *)
        echo "Usage: $0 {check|report|validate}"
        echo ""
        echo "Commands:"
        echo "  check    - Check for infrastructure drift"
        echo "  report   - Generate detailed drift report"
        echo "  validate - Validate Terraform configuration"
        exit 1
        ;;
esac

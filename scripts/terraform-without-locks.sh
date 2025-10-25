#!/bin/bash

# Terraform Without Locks
# Wrapper script that runs terraform with lock disabled for problematic environments

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

# Main function
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "init")
            log_info "Running terraform init without locks..."
            # Handle migration confirmation automatically
            echo "yes" | terraform init -lock=false "$@"
            ;;
        "plan")
            log_info "Running terraform plan without locks..."
            terraform plan -lock=false "$@"
            ;;
        "apply")
            log_info "Running terraform apply without locks..."
            terraform apply -lock=false "$@"
            ;;
        "destroy")
            log_info "Running terraform destroy without locks..."
            terraform destroy -lock=false "$@"
            ;;
        "validate")
            log_info "Running terraform validate..."
            terraform validate "$@"
            ;;
        "output")
            log_info "Running terraform output..."
            terraform output "$@"
            ;;
        "show")
            log_info "Running terraform show..."
            terraform show "$@"
            ;;
        "state")
            log_info "Running terraform state..."
            terraform state "$@"
            ;;
        "import")
            log_info "Running terraform import..."
            terraform import -lock=false "$@"
            ;;
        "force-unlock")
            log_info "Running terraform force-unlock..."
            terraform force-unlock -force "$@"
            ;;
        "help"|*)
            echo "Usage: $0 <command> [terraform-args...]"
            echo ""
            echo "Commands:"
            echo "  init         - terraform init (no locks)"
            echo "  plan         - terraform plan (no locks)"
            echo "  apply        - terraform apply (no locks)"
            echo "  destroy      - terraform destroy (no locks)"
            echo "  validate     - terraform validate"
            echo "  output       - terraform output"
            echo "  show         - terraform show"
            echo "  state        - terraform state"
            echo "  import       - terraform import (no locks)"
            echo "  force-unlock - terraform force-unlock"
            echo "  help         - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 plan -var-file=production.tfvars"
            echo "  $0 apply -auto-approve"
            echo "  $0 import aws_s3_bucket.example bucket-name"
            ;;
    esac
}

# Run main function
main "$@"

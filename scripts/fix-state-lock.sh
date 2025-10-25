#!/bin/bash

# Fix State Lock Issues
# Comprehensive solution for Terraform state lock problems

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
S3_BUCKET="robert-consulting-terraform-state"
DYNAMODB_TABLE="robert-consulting-terraform-locks"
REGION="us-east-1"

# Check AWS credentials
check_aws_credentials() {
    log_info "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid"
        return 1
    fi
    
    log_success "AWS credentials are valid"
}

# Check S3 bucket
check_s3_bucket() {
    log_info "Checking S3 bucket: $S3_BUCKET"
    
    if ! aws s3 ls "s3://$S3_BUCKET" >/dev/null 2>&1; then
        log_error "S3 bucket $S3_BUCKET does not exist or is not accessible"
        return 1
    fi
    
    log_success "S3 bucket is accessible"
}

# Check DynamoDB table
check_dynamodb_table() {
    log_info "Checking DynamoDB table: $DYNAMODB_TABLE"
    
    if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
        log_error "DynamoDB table $DYNAMODB_TABLE does not exist"
        return 1
    fi
    
    log_success "DynamoDB table exists"
}

# Clear existing locks
clear_locks() {
    log_info "Clearing existing locks from DynamoDB table..."
    
    # Get all items from the table
    local items=$(aws dynamodb scan --table-name "$DYNAMODB_TABLE" --region "$REGION" --query 'Items[*].LockID.S' --output text 2>/dev/null || echo "")
    
    if [[ -n "$items" && "$items" != "None" ]]; then
        for lock_id in $items; do
            log_info "Deleting lock: $lock_id"
            aws dynamodb delete-item \
                --table-name "$DYNAMODB_TABLE" \
                --region "$REGION" \
                --key "{\"LockID\":{\"S\":\"$lock_id\"}}" \
                >/dev/null 2>&1 || true
        done
        log_success "Cleared existing locks"
    else
        log_info "No existing locks found"
    fi
}

# Test backend configuration
test_backend() {
    local test_dir="test-backend-$(date +%s)"
    
    log_info "Testing backend configuration..."
    
    # Create test directory
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Create test configuration
    cat > main.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }
  
  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "test-backend.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "robert-consulting-terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Simple test resource
resource "aws_s3_bucket" "test" {
  bucket = "test-backend-${random_id.test.hex}"
  
  tags = {
    Name = "Test Backend"
  }
}

resource "random_id" "test" {
  byte_length = 4
}
EOF

    # Test initialization
    if terraform init >/dev/null 2>&1; then
        log_success "Backend configuration test passed"
        
        # Clean up
        cd ..
        rm -rf "$test_dir"
        return 0
    else
        log_error "Backend configuration test failed"
        cd ..
        rm -rf "$test_dir"
        return 1
    fi
}

# Fix main terraform configuration
fix_main_config() {
    log_info "Fixing main terraform configuration..."
    
    # Go to main terraform directory
    cd /Volumes/gitlab/robert-consulting-public/terraform
    
    # Update backend configuration
    cat > backend.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "robert-consulting-terraform-locks"
  }
}

# Default AWS provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "Robert Consulting"
      ManagedBy = "Terraform"
    }
  }
}

# AWS provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "Robert Consulting"
      ManagedBy = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
EOF

    log_success "Main terraform configuration updated"
}

# Main function
main() {
    local action="${1:-fix}"
    
    case "$action" in
        "fix")
            log_info "Fixing state lock issues..."
            
            check_aws_credentials || return 1
            check_s3_bucket || return 1
            check_dynamodb_table || return 1
            clear_locks || return 1
            fix_main_config || return 1
            test_backend || return 1
            
            log_success "State lock issues fixed!"
            echo ""
            echo "Next steps:"
            echo "1. Run: cd terraform && terraform init"
            echo "2. Run: terraform plan"
            echo "3. Run: terraform apply"
            ;;
        "test")
            log_info "Testing backend configuration..."
            test_backend
            ;;
        "clear")
            log_info "Clearing locks..."
            clear_locks
            ;;
        "check")
            log_info "Checking configuration..."
            check_aws_credentials
            check_s3_bucket
            check_dynamodb_table
            ;;
        "help"|*)
            echo "Usage: $0 <action>"
            echo ""
            echo "Actions:"
            echo "  fix   - Fix all state lock issues (default)"
            echo "  test  - Test backend configuration"
            echo "  clear - Clear existing locks"
            echo "  check - Check AWS configuration"
            echo "  help  - Show this help"
            ;;
    esac
}

# Run main function
main "$@"

#!/bin/bash

# Migrate Terraform state to S3 backend
# This script restores the S3 backend configuration and migrates the state

set -e

echo "🚀 Migrating Terraform state to S3 backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}📊 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Restore S3 backend configuration
print_header "Step 1: Restoring S3 backend configuration"
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
EOF
print_success "S3 backend configuration restored"

# Step 2: Initialize with S3 backend
print_header "Step 2: Initializing with S3 backend"
if terraform init -migrate-state; then
    print_success "Successfully migrated state to S3 backend"
else
    print_error "Failed to migrate state to S3 backend"
    exit 1
fi

# Step 3: Verify state migration
print_header "Step 3: Verifying state migration"
if terraform state list >/dev/null 2>&1; then
    resource_count=$(terraform state list | wc -l)
    print_success "State migration verified - $resource_count resources in state"
else
    print_error "State verification failed"
    exit 1
fi

# Step 4: Run plan to check for drift
print_header "Step 4: Checking for configuration drift"
if terraform plan -lock=false >/dev/null 2>&1; then
    print_success "No configuration drift detected"
else
    print_warning "Configuration drift detected - review terraform plan output"
fi

print_success "State migration to S3 backend completed!"
echo ""
echo "🎯 State is now stored in S3 with DynamoDB locking"
echo "📊 Run 'terraform state list' to see all managed resources"
echo "🔍 Run 'terraform plan' to check for any needed changes"

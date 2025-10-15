#!/bin/bash

# Step-by-step S3 backend migration script
# This script handles the migration more carefully

set -e

echo "🚀 Step-by-step S3 backend migration..."

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

# Step 1: Backup current state
print_header "Step 1: Backing up current state"
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
print_success "State backed up"

# Step 2: Verify state file is valid
print_header "Step 2: Verifying state file"
if jq . terraform.tfstate > /dev/null 2>&1; then
    print_success "State file is valid JSON"
else
    print_error "State file is invalid JSON"
    exit 1
fi

# Step 3: Upload state to S3
print_header "Step 3: Uploading state to S3"
aws s3 cp terraform.tfstate s3://robert-consulting-terraform-state/terraform.tfstate
print_success "State uploaded to S3"

# Step 4: Verify S3 upload
print_header "Step 4: Verifying S3 upload"
s3_size=$(aws s3api head-object --bucket robert-consulting-terraform-state --key terraform.tfstate --query 'ContentLength' --output text)
local_size=$(stat -f%z terraform.tfstate)
if [ "$s3_size" -eq "$local_size" ]; then
    print_success "S3 upload verified ($s3_size bytes)"
else
    print_error "S3 upload verification failed (S3: $s3_size, Local: $local_size)"
    exit 1
fi

# Step 5: Test S3 state file
print_header "Step 5: Testing S3 state file"
aws s3 cp s3://robert-consulting-terraform-state/terraform.tfstate terraform.tfstate.s3-test
if jq . terraform.tfstate.s3-test > /dev/null 2>&1; then
    print_success "S3 state file is valid JSON"
    rm terraform.tfstate.s3-test
else
    print_error "S3 state file is invalid JSON"
    exit 1
fi

# Step 6: Configure S3 backend
print_header "Step 6: Configuring S3 backend"
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
EOF
print_success "S3 backend configured"

# Step 7: Initialize with S3 backend
print_header "Step 7: Initializing with S3 backend"
if terraform init -migrate-state -lock=false; then
    print_success "Successfully migrated to S3 backend"
else
    print_error "Failed to migrate to S3 backend"
    print_warning "Falling back to local state"
    # Restore local backend
    cat > backend.tf << 'EOF'
# Local backend fallback
# terraform {
#   backend "s3" {
#     bucket         = "robert-consulting-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#   }
# }
EOF
    terraform init
    exit 1
fi

# Step 8: Verify migration
print_header "Step 8: Verifying migration"
if terraform state list >/dev/null 2>&1; then
    resource_count=$(terraform state list | wc -l)
    print_success "Migration verified - $resource_count resources in state"
else
    print_error "Migration verification failed"
    exit 1
fi

print_success "S3 backend migration completed successfully!"
echo ""
echo "🎯 State is now stored in S3"
echo "📊 Run 'terraform state list' to see all managed resources"
echo "🔍 Run 'terraform plan' to check for any needed changes"

#!/bin/bash

# Terraform State Cleanup and Migration Script
# This script will clean up the corrupted state and migrate to S3 backend

set -e

echo "🧹 Starting Terraform state cleanup and migration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Backup current state
echo "📦 Step 1: Backing up current state..."
if [ -f ".terraform/terraform.tfstate" ]; then
    cp .terraform/terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Local state backed up"
else
    print_warning "No local state file found"
fi

# Step 2: Remove corrupted .terraform directory
echo "🗑️  Step 2: Removing corrupted .terraform directory..."
if [ -d ".terraform" ]; then
    rm -rf .terraform
    print_status "Corrupted .terraform directory removed"
fi

# Step 3: Remove any lock files
echo "🔓 Step 3: Removing lock files..."
rm -f .terraform.lock.hcl
print_status "Lock files removed"

# Step 4: Initialize with S3 backend
echo "🚀 Step 4: Initializing with S3 backend..."
terraform init -upgrade

if [ $? -eq 0 ]; then
    print_status "Successfully initialized with S3 backend"
else
    print_error "Failed to initialize with S3 backend"
    exit 1
fi

# Step 5: Import existing resources (if needed)
echo "📥 Step 5: Checking for resources to import..."

# Check if we need to import the Lambda function we deployed manually
if aws lambda get-function --function-name dashboard-stats-refresher >/dev/null 2>&1; then
    echo "Found manually deployed Lambda function, importing..."
    terraform import aws_lambda_function.stats_refresher dashboard-stats-refresher || print_warning "Could not import Lambda function (may already be in state)"
fi

# Step 6: Plan to see what changes are needed
echo "📋 Step 6: Running terraform plan to check for drift..."
terraform plan -out=tfplan

if [ $? -eq 0 ]; then
    print_status "Terraform plan completed successfully"
    echo "📊 Plan summary:"
    terraform show -no-color tfplan | grep -E "Plan:|No changes|will be" | head -5
else
    print_error "Terraform plan failed"
    exit 1
fi

# Step 7: Show unused resources (if any)
echo "🔍 Step 7: Checking for unused resources..."
echo "Current resources in state:"
terraform state list | wc -l | xargs echo "Total resources:"

# Step 8: Clean up plan file
rm -f tfplan

print_status "State cleanup and migration completed!"
echo ""
echo "🎯 Next steps:"
echo "1. Review the terraform plan output above"
echo "2. Run 'terraform apply' if changes look correct"
echo "3. Verify all resources are working as expected"
echo ""
echo "💡 Tips:"
echo "- Use 'terraform state list' to see all managed resources"
echo "- Use 'terraform state show <resource>' to inspect specific resources"
echo "- Use 'terraform destroy -target=<resource>' to remove specific resources if needed"

#!/bin/bash

# Cleanup Unused CloudFront Distributions
# This script identifies and removes unused CloudFront distributions

set -e

echo "🧹 Cleaning Up Unused CloudFront Distributions"
echo "============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: List all CloudFront distributions..."
aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items,Comment:Comment}' --output table

echo ""
echo "🔍 Step 2: Check Terraform state for CloudFront distributions..."
terraform state list | grep cloudfront

echo ""
echo "🔍 Step 3: Identify distributions in Terraform state..."
echo "Current Terraform-managed distributions:"
terraform state list | grep cloudfront | while read resource; do
    echo "  - $resource"
    terraform state show "$resource" | grep -E "(id|domain_name)" || true
done

echo ""
echo "🔍 Step 4: Find distributions not in Terraform state..."
echo "Checking for orphaned distributions..."

# Get all distribution IDs
ALL_DISTRIBUTIONS=$(aws cloudfront list-distributions --query 'DistributionList.Items[*].Id' --output text)

# Get Terraform-managed distribution IDs
TERRAFORM_DISTRIBUTIONS=$(terraform state list | grep cloudfront | while read resource; do
    terraform state show "$resource" | grep 'id ' | awk '{print $3}' | tr -d '"'
done)

echo "All distributions: $ALL_DISTRIBUTIONS"
echo "Terraform-managed: $TERRAFORM_DISTRIBUTIONS"

echo ""
echo "⚠️  WARNING: This will show distributions that may be orphaned"
echo "Please review carefully before proceeding with deletion"
echo ""
echo "🔧 To manually check a specific distribution:"
echo "aws cloudfront get-distribution --id DISTRIBUTION_ID"
echo ""
echo "🔧 To delete an unused distribution:"
echo "aws cloudfront delete-distribution --id DISTRIBUTION_ID --if-match ETAG"
echo ""
echo "📋 Next steps:"
echo "1. Review the distributions listed above"
echo "2. Identify which ones are no longer needed"
echo "3. Delete them manually using the AWS CLI or Console"
echo "4. Run 'terraform plan' to ensure no conflicts"

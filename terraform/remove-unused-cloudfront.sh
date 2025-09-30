#!/bin/bash

# Remove Unused CloudFront Distributions
# This script identifies and removes CloudFront distributions not managed by Terraform

set -e

echo "🗑️  Removing Unused CloudFront Distributions"
echo "==========================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Get all CloudFront distributions..."
ALL_DISTRIBUTIONS=$(aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Comment:Comment}' --output json)

echo "🔍 Step 2: Get Terraform-managed distribution IDs..."
TERRAFORM_DISTRIBUTIONS=""
for resource in $(terraform state list | grep cloudfront); do
    DIST_ID=$(terraform state show "$resource" | grep 'id ' | awk '{print $3}' | tr -d '"')
    if [ -n "$DIST_ID" ]; then
        TERRAFORM_DISTRIBUTIONS="$TERRAFORM_DISTRIBUTIONS $DIST_ID"
    fi
done

echo "Terraform-managed distributions: $TERRAFORM_DISTRIBUTIONS"

echo ""
echo "🔍 Step 3: Find orphaned distributions..."
ORPHANED_DISTRIBUTIONS=""

# Parse the JSON to find distributions not in Terraform
echo "$ALL_DISTRIBUTIONS" | jq -r '.[] | select(.Status == "Deployed") | .Id' | while read DIST_ID; do
    if [[ ! " $TERRAFORM_DISTRIBUTIONS " =~ " $DIST_ID " ]]; then
        echo "Found orphaned distribution: $DIST_ID"
        ORPHANED_DISTRIBUTIONS="$ORPHANED_DISTRIBUTIONS $DIST_ID"
    fi
done

if [ -z "$ORPHANED_DISTRIBUTIONS" ]; then
    echo "✅ No orphaned distributions found"
    exit 0
fi

echo ""
echo "⚠️  Found orphaned distributions: $ORPHANED_DISTRIBUTIONS"
echo ""
echo "🔍 Step 4: Show details of orphaned distributions..."
for DIST_ID in $ORPHANED_DISTRIBUTIONS; do
    echo "Distribution ID: $DIST_ID"
    aws cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items,Comment:Comment,LastModifiedTime:LastModifiedTime}' --output table
    echo ""
done

echo "⚠️  WARNING: These distributions will be deleted!"
echo "Please review the details above before proceeding."
echo ""
read -p "Do you want to proceed with deletion? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deletion cancelled"
    exit 1
fi

echo "🔧 Step 5: Deleting orphaned distributions..."
for DIST_ID in $ORPHANED_DISTRIBUTIONS; do
    echo "Deleting distribution: $DIST_ID"
    
    # Get the ETag for the distribution
    ETAG=$(aws cloudfront get-distribution --id "$DIST_ID" --query 'ETag' --output text)
    
    # Disable the distribution first
    echo "Disabling distribution: $DIST_ID"
    aws cloudfront get-distribution-config --id "$DIST_ID" --query 'DistributionConfig' --output json > /tmp/dist-config.json
    jq '.Enabled = false' /tmp/dist-config.json > /tmp/dist-config-disabled.json
    
    # Update the distribution to disable it
    aws cloudfront update-distribution --id "$DIST_ID" --distribution-config file:///tmp/dist-config-disabled.json --if-match "$ETAG"
    
    # Wait for the distribution to be disabled
    echo "Waiting for distribution to be disabled..."
    aws cloudfront wait distribution-deployed --id "$DIST_ID"
    
    # Delete the distribution
    echo "Deleting distribution: $DIST_ID"
    aws cloudfront delete-distribution --id "$DIST_ID" --if-match "$ETAG"
    
    echo "✅ Deleted distribution: $DIST_ID"
done

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to ensure no conflicts"
echo "2. Run 'terraform apply' to deploy current configuration"

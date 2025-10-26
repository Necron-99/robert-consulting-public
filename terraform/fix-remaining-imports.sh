#!/bin/bash

echo "🔧 === FIXING REMAINING IMPORT ISSUES ==="
echo ""
echo "This script will fix the remaining import issues:"
echo "1. Skip Lambda functions already in state"
echo "2. Fix Secrets Manager import with proper ARN"
echo "3. Import WAF resources with proper ARNs"
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 STEP 1: Get Secrets Manager ARN"
echo "=================================="
echo "Getting the ARN for github-token-dashboard-stats..."
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id github-token-dashboard-stats --query 'ARN' --output text --region us-east-1)
echo "Secret ARN: $SECRET_ARN"

if [ -n "$SECRET_ARN" ]; then
    echo "Importing Secrets Manager secret with proper ARN..."
    terraform import aws_secretsmanager_secret.github_token "$SECRET_ARN"
else
    echo "❌ Could not find the secret ARN"
fi

echo ""
echo "📋 STEP 2: Get WAF Web ACL ARNs"
echo "==============================="
echo "Getting WAF Web ACL ARNs..."

# Get REGIONAL WAF Web ACLs
echo "Regional WAF Web ACLs:"
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 --query 'WebACLs[].{Name:Name,ARN:ARN}' --output table

# Get CLOUDFRONT WAF Web ACLs  
echo ""
echo "CloudFront WAF Web ACLs:"
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query 'WebACLs[].{Name:Name,ARN:ARN}' --output table

echo ""
echo "📋 STEP 3: Get CloudFront Response Headers Policy IDs"
echo "===================================================="
echo "Getting CloudFront response headers policy IDs..."
aws cloudfront list-response-headers-policies --query 'ResponseHeadersPolicyList.Items[].{Name:Name,Id:Id}' --output table

echo ""
echo "📋 STEP 4: Get CloudFront Function Names"
echo "========================================"
echo "Getting CloudFront function names..."
aws cloudfront list-functions --query 'FunctionList.Items[].{Name:Name}' --output table

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Use the ARNs/IDs above to import the remaining resources"
echo "2. Run terraform plan to see what's left"
echo "3. Apply the remaining changes"
echo ""
echo "⚠️  Note: Lambda functions are already imported, so we can skip those."
echo ""
echo "🚀 Ready to continue with the imports!"

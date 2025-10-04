#!/bin/bash

# Fix Terraform State for robertconsulting.net
# This script resolves state issues and imports existing resources

set -e

echo "🔧 Fixing Terraform State for robertconsulting.net"
echo "================================================"

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Checking current Terraform state..."
terraform state list

echo ""
echo "🔧 Step 1: Destroy problematic certificate validation..."
# Destroy the certificate validation that's causing issues
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve || true

echo ""
echo "🔧 Step 2: Import existing certificate..."
# Import the existing certificate
CERT_ARN="arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"
terraform import aws_acm_certificate.wildcard "$CERT_ARN"

echo ""
echo "🔧 Step 3: Check certificate status..."
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus,Domain:DomainName}' --output table

echo ""
echo "🔧 Step 4: Import Route 53 hosted zone if it exists..."
# Check if hosted zone exists
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | sed 's|/hostedzone/||')
if [ -n "$HOSTED_ZONE_ID" ]; then
    echo "✅ Found existing hosted zone: $HOSTED_ZONE_ID"
    terraform import aws_route53_zone.main "$HOSTED_ZONE_ID"
else
    echo "⚠️  No existing hosted zone found, will create new one"
fi

echo ""
echo "🔧 Step 5: Import existing DNS validation records..."
# Import validation records if they exist
terraform import aws_route53_record.cert_validation["robertconsulting.net"] "$HOSTED_ZONE_ID_robertconsulting.net_CNAME" || true
terraform import aws_route53_record.cert_validation["*.robertconsulting.net"] "$HOSTED_ZONE_ID_*.robertconsulting.net_CNAME" || true

echo ""
echo "🔧 Step 6: Plan the deployment..."
terraform plan

echo ""
echo "🔧 Step 7: Apply the changes..."
terraform apply

echo ""
echo "✅ Terraform state fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. Check that all resources are properly imported"
echo "2. Run 'terraform plan' to see if there are any remaining issues"
echo "3. Run 'terraform apply' to complete the deployment"
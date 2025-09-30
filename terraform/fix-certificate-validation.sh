#!/bin/bash

# Fix SSL Certificate Validation for robertconsulting.net
# This script helps resolve certificate validation timeouts

set -e

echo "🔧 Fixing SSL Certificate Validation for robertconsulting.net"
echo "=========================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Checking current certificate status..."

# Get the certificate ARN from the error message
CERT_ARN="arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

echo "📋 Certificate ARN: $CERT_ARN"

# Check certificate status
echo "🔍 Checking certificate validation status..."
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

echo ""
echo "🔧 Fixing certificate validation..."

# Option 1: Destroy the problematic certificate validation resource
echo "1. Destroying the certificate validation resource..."
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve

# Option 2: Import the existing certificate
echo "2. Importing the existing certificate..."
terraform import aws_acm_certificate.wildcard "$CERT_ARN"

# Option 3: Recreate the validation
echo "3. Recreating certificate validation..."
terraform apply -target=aws_acm_certificate_validation.wildcard

echo ""
echo "✅ Certificate validation fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. Check that DNS validation records are properly set in Route 53"
echo "2. Wait 2-3 minutes for DNS propagation"
echo "3. Run 'terraform apply' to complete the deployment"
echo ""
echo "🔍 To check certificate status:"
echo "aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1"
#!/bin/bash

# Step-by-Step Deployment for robertconsulting.net
# This script handles the deployment in phases to avoid certificate issues

set -e

echo "🚀 Step-by-Step Deployment for robertconsulting.net"
echo "==============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔧 Phase 1: Deploy infrastructure without custom domains..."
echo "This will create the CloudFront distribution with default certificate"

# Apply the changes
terraform apply

echo ""
echo "✅ Phase 1 Complete! CloudFront distribution created"
echo ""
echo "📋 Phase 2: Manual Certificate Validation"
echo "========================================"
echo "1. Get the validation records:"
CERT_ARN="arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

echo ""
echo "2. Add these CNAME records to your DNS provider (Route 53 or your registrar)"
echo "3. Wait 5-10 minutes for DNS propagation"
echo "4. Check certificate status:"
echo "   aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.Status'"
echo ""
echo "5. Once certificate shows 'ISSUED', run Phase 3:"
echo "   ./terraform/enable-custom-domains.sh"

echo ""
echo "📋 Current Status:"
echo "================="
echo "✅ CloudFront distribution created"
echo "✅ S3 bucket configured"
echo "✅ Route 53 hosted zone created"
echo "⏳ Certificate validation pending"
echo "⏳ Custom domains not yet enabled"
echo ""
echo "🌐 Your site is accessible at:"
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_distribution_domain_name)
echo "https://$CLOUDFRONT_DOMAIN"
echo ""
echo "📋 Next steps:"
echo "1. Validate the certificate (see instructions above)"
echo "2. Update your domain nameservers: terraform output name_servers"
echo "3. Once certificate is validated, enable custom domains"

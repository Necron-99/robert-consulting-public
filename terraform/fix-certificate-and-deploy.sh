#!/bin/bash

# Fix Certificate and Deploy robertconsulting.net
# This script handles certificate validation and deployment properly

set -e

echo "🔧 Fixing Certificate and Deploying robertconsulting.net"
echo "====================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

CERT_ARN="arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

echo "🔍 Step 1: Check certificate status..."
CERT_STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.Status' --output text)
echo "Certificate Status: $CERT_STATUS"

if [ "$CERT_STATUS" = "ISSUED" ]; then
    echo "✅ Certificate is already validated!"
    echo "🔧 Updating CloudFront to use the certificate..."
    
    # Update the infrastructure.tf to use the certificate
    sed -i 's/cloudfront_default_certificate = true/acm_certificate_arn = aws_acm_certificate.wildcard.arn/' infrastructure.tf
    sed -i 's/minimum_protocol_version        = "TLSv1.2_2021"/ssl_support_method       = "sni-only"\n    minimum_protocol_version = "TLSv1.2_2021"/' infrastructure.tf
    
    echo "🔧 Applying changes with validated certificate..."
    terraform apply
else
    echo "⚠️  Certificate is still pending validation"
    echo "🔧 Deploying with CloudFront default certificate first..."
    
    # Deploy with default certificate
    terraform apply
    
    echo ""
    echo "📋 Manual Certificate Validation Steps:"
    echo "1. Get the validation records:"
    aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
    
    echo ""
    echo "2. Add these CNAME records to your DNS provider"
    echo "3. Wait 5-10 minutes for DNS propagation"
    echo "4. Check certificate status:"
    echo "   aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.Status'"
    echo "5. Once validated, update CloudFront to use the certificate"
fi

echo ""
echo "✅ Deployment process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update your domain nameservers to point to Route 53"
echo "2. Wait 5-60 minutes for DNS propagation"
echo "3. Test your domain: https://robertconsulting.net"
echo "4. Test WWW subdomain: https://www.robertconsulting.net"
echo ""
echo "🔍 To get nameservers:"
echo "terraform output name_servers"

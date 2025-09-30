#!/bin/bash

# Enable HTTPS and Custom Domains for robertconsulting.net
# This script enables HTTPS and custom domains once certificate is validated

set -e

echo "🔧 Enabling HTTPS and Custom Domains for robertconsulting.net"
echo "============================================================"

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

CERT_ARN="arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

echo "🔍 Step 1: Check certificate status..."
CERT_STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.Status' --output text)
echo "Certificate Status: $CERT_STATUS"

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not yet validated. Status: $CERT_STATUS"
    echo "Please validate the certificate first by adding the DNS validation records."
    echo "Run: aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table"
    exit 1
fi

echo "✅ Certificate is validated! Proceeding with HTTPS and custom domain setup..."

echo ""
echo "🔧 Step 2: Update CloudFront configuration for HTTPS and custom domains..."
# Update the infrastructure.tf to use the certificate, enable HTTPS, and add aliases
sed -i 's/cloudfront_default_certificate = true/acm_certificate_arn = aws_acm_certificate.wildcard.arn/' infrastructure.tf
sed -i '/acm_certificate_arn = aws_acm_certificate.wildcard.arn/a\    ssl_support_method       = "sni-only"\n    minimum_protocol_version = "TLSv1.2_2021"' infrastructure.tf
sed -i 's/viewer_protocol_policy = "allow-all"/viewer_protocol_policy = "redirect-to-https"/' infrastructure.tf
sed -i 's/# aliases = \["robertconsulting.net", "www.robertconsulting.net"\]  # Commented out until certificate is validated/aliases = ["robertconsulting.net", "www.robertconsulting.net"]/' infrastructure.tf

echo ""
echo "🔧 Step 3: Apply the changes..."
terraform apply

echo ""
echo "✅ HTTPS and custom domains enabled!"
echo ""
echo "📋 Next steps:"
echo "1. Update your domain nameservers: terraform output name_servers"
echo "2. Wait 5-60 minutes for DNS propagation"
echo "3. Test your domain: https://robertconsulting.net"
echo "4. Test WWW subdomain: https://www.robertconsulting.net"

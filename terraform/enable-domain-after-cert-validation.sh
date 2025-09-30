#!/bin/bash

# Enable domain aliases after certificate validation
echo "🔧 Enabling Domain Aliases After Certificate Validation"
echo "====================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

# Check certificate status
CERT_ARN=$(terraform output -raw certificate_arn)
CERT_STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.Status' --output text)

echo "🔍 Certificate Status: $CERT_STATUS"

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not yet validated. Current status: $CERT_STATUS"
    echo "⏱️  Please wait for certificate validation and try again."
    echo ""
    echo "To check status manually:"
    echo "aws acm describe-certificate --certificate-arn \"$CERT_ARN\" --region us-east-1 --query 'Certificate.Status' --output text"
    exit 1
fi

echo "✅ Certificate is validated! Proceeding with domain setup..."

# Uncomment aliases in infrastructure.tf
echo "🔧 Enabling aliases in infrastructure.tf..."
sed -i 's/# aliases = \["robertconsulting.net", "www.robertconsulting.net"\]/aliases = ["robertconsulting.net", "www.robertconsulting.net"]/' infrastructure.tf

# Update viewer certificate to use the validated certificate
echo "🔧 Updating viewer certificate to use validated certificate..."
sed -i 's/cloudfront_default_certificate = true/acm_certificate_arn = "'"$CERT_ARN"'"/' infrastructure.tf
sed -i 's/ssl_support_method = "sni-only"/ssl_support_method = "sni-only"\n    minimum_protocol_version = "TLSv1.2_2021"/' infrastructure.tf

echo "🚀 Applying changes..."
terraform plan

echo ""
echo "✅ Changes ready to apply!"
echo "Run 'terraform apply' to enable your domain."
echo ""
echo "After applying, your domain will work at:"
echo "  - https://robertconsulting.net"
echo "  - https://www.robertconsulting.net"

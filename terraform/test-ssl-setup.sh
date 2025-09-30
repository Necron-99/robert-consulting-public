#!/bin/bash

# Test SSL Certificate and CloudFront Setup
# This script tests the SSL certificate and CloudFront configuration

set -e

echo "🧪 Testing SSL Certificate and CloudFront Setup"
echo "==============================================="

# Check if we're in the terraform directory
if [ ! -f "domain-namecheap.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Checking Certificate Status..."

# Get certificate details
CERT_ARN=$(terraform output -raw certificate_arn)
echo "📋 Certificate ARN: $CERT_ARN"

# Check certificate status
CERT_STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.Status' --output text)
echo "🔒 Certificate Status: $CERT_STATUS"

if [ "$CERT_STATUS" != "ISSUED" ]; then
    echo "❌ Certificate is not issued yet. Status: $CERT_STATUS"
    echo "Please wait for certificate validation to complete."
    exit 1
fi

echo "✅ Certificate is issued and ready!"

echo ""
echo "🔍 Step 2: Checking CloudFront Distribution..."

# Get CloudFront distribution details
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
echo "📋 Distribution ID: $DISTRIBUTION_ID"

# Check CloudFront status
DIST_STATUS=$(aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query 'Distribution.Status' --output text)
echo "🌐 CloudFront Status: $DIST_STATUS"

if [ "$DIST_STATUS" != "Deployed" ]; then
    echo "⚠️  CloudFront is still deploying. Status: $DIST_STATUS"
    echo "This may take 10-15 minutes. You can check status with:"
    echo "aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text"
fi

echo ""
echo "🔍 Step 3: Testing HTTPS URLs..."

# Get CloudFront domain
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_distribution_domain_name)
echo "📋 CloudFront Domain: $CLOUDFRONT_DOMAIN"

echo ""
echo "🧪 Testing URLs (these should work with HTTPS):"
echo "=============================================="

# Test CloudFront domain
echo "1. CloudFront HTTPS:"
echo "   https://$CLOUDFRONT_DOMAIN"
echo "   Testing..."
if curl -s -I "https://$CLOUDFRONT_DOMAIN" | grep -q "HTTP/2 200\|HTTP/1.1 200"; then
    echo "   ✅ CloudFront HTTPS working"
else
    echo "   ⚠️  CloudFront HTTPS not responding yet (may still be deploying)"
fi

echo ""
echo "2. Custom Domain (if DNS is configured):"
echo "   https://robertconsulting.net"
echo "   https://www.robertconsulting.net"
echo ""
echo "   To test these, you need to:"
echo "   - Add A record at Namecheap: robertconsulting.net → CloudFront IP"
echo "   - Keep existing CNAME: www.robertconsulting.net → dpm4biqgmoi9l.cloudfront.net"

echo ""
echo "🔍 Step 4: SSL Certificate Details..."

# Get certificate details
echo "📋 Certificate Information:"
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.{DomainName:DomainName,SubjectAlternativeNames:SubjectAlternativeNames,Status:Status,NotBefore:NotBefore,NotAfter:NotAfter}' --output table

echo ""
echo "🔍 Step 5: DNS Configuration for Namecheap..."

echo "📋 Add these records at Namecheap:"
echo "=================================="
echo ""
echo "1. A Record (for root domain):"
echo "   Name: @ (or robertconsulting.net)"
echo "   Value: [Get CloudFront IP from AWS Console]"
echo "   TTL: 300"
echo ""
echo "2. CNAME Record (keep existing):"
echo "   Name: www"
echo "   Value: dpm4biqgmoi9l.cloudfront.net"
echo "   TTL: 300"
echo ""
echo "3. Optional CNAME Records (for subdomains):"
echo "   Name: api"
echo "   Value: dpm4biqgmoi9l.cloudfront.net"
echo "   TTL: 300"

echo ""
echo "🔍 Step 6: Testing Commands..."

echo "📋 Manual Testing Commands:"
echo "==========================="
echo ""
echo "# Test CloudFront directly:"
echo "curl -I https://$CLOUDFRONT_DOMAIN"
echo ""
echo "# Test with custom domain (after DNS setup):"
echo "curl -I https://robertconsulting.net"
echo "curl -I https://www.robertconsulting.net"
echo ""
echo "# Check SSL certificate details:"
echo "openssl s_client -connect robertconsulting.net:443 -servername robertconsulting.net"
echo ""
echo "# Test from different locations:"
echo "nslookup robertconsulting.net"
echo "dig robertconsulting.net"

echo ""
echo "✅ SSL Certificate Setup Complete!"
echo "=================================="
echo ""
echo "📋 Next Steps:"
echo "1. Add DNS records at Namecheap (shown above)"
echo "2. Wait 5-10 minutes for DNS propagation"
echo "3. Test your domains: https://robertconsulting.net"
echo "4. Monitor CloudFront deployment status"
echo ""
echo "🔍 To check CloudFront status:"
echo "aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text"
echo ""
echo "🎉 Your SSL certificate is ready and CloudFront is being updated!"


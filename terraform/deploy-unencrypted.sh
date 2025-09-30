#!/bin/bash

# Deploy robertconsulting.net with unencrypted access
# This script deploys the site with HTTP access until certificate is validated

set -e

echo "🚀 Deploying robertconsulting.net with unencrypted access"
echo "====================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔧 Deploying infrastructure with HTTP access..."
terraform apply

echo ""
echo "✅ Deployment completed!"
echo ""
echo "📋 Current Status:"
echo "================="
echo "✅ CloudFront distribution created"
echo "✅ S3 bucket configured"
echo "✅ Route 53 hosted zone created"
echo "✅ HTTP access enabled (unencrypted)"
echo "⏳ Certificate validation pending"
echo "⏳ Custom domains not yet enabled"
echo ""
echo "🌐 Your site is accessible at:"
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_distribution_domain_name)
echo "http://$CLOUDFRONT_DOMAIN"
echo ""
echo "📋 Next steps:"
echo "1. Update your domain nameservers: terraform output name_servers"
echo "2. Test the site works with HTTP"
echo "3. Validate the certificate when ready"
echo "4. Enable HTTPS and custom domains later"
echo ""
echo "🔍 To get nameservers:"
echo "terraform output name_servers"

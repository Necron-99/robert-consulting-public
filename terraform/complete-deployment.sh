#!/bin/bash

# Complete the deployment without certificate validation
# This script finishes the domain migration to robertconsulting.net

set -e

echo "🚀 Completing Deployment to robertconsulting.net"
echo "=============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔧 Step 1: Destroy the problematic certificate validation..."
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve || true

echo ""
echo "🔧 Step 2: Plan the deployment..."
terraform plan

echo ""
echo "🔧 Step 3: Apply the changes..."
terraform apply

echo ""
echo "✅ Deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update your domain nameservers to point to Route 53"
echo "2. Wait 5-60 minutes for DNS propagation"
echo "3. Test your domain: https://robertconsulting.net"
echo "4. Test WWW subdomain: https://www.robertconsulting.net"
echo ""
echo "🔍 To get nameservers:"
echo "terraform output name_servers"

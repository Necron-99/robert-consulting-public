#!/bin/bash

# Fix CloudFront aliases for robertconsulting.net
echo "🔧 Fixing CloudFront aliases for robertconsulting.net"
echo "=================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "📋 Current CloudFront configuration:"
aws cloudfront get-distribution --id E36DBYPHUUKB3V --query 'Distribution.DistributionConfig.Aliases.Items' --output table

echo ""
echo "🚀 Applying Terraform changes..."
terraform plan

echo ""
echo "✅ Changes planned. Run 'terraform apply' to apply them."
echo ""
echo "After applying, your domain should work at:"
echo "  - https://robertconsulting.net"
echo "  - https://www.robertconsulting.net"

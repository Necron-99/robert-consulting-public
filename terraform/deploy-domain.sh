#!/bin/bash

# Deploy Domain and SSL Certificate for robertconsulting.net
# This script automates the deployment of the domain infrastructure

set -e

echo "🚀 Starting domain deployment for robertconsulting.net"
echo "=================================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

# Check if AWS CLI is configured
echo "🔍 Checking AWS configuration..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured or no valid credentials"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS credentials verified"

# Initialize Terraform if needed
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning infrastructure changes..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
echo "⚠️  IMPORTANT: Before proceeding, ensure you have:"
echo "   1. Ownership of robertconsulting.net domain"
echo "   2. Access to your domain registrar to update nameservers"
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply the changes
echo "🚀 Deploying infrastructure..."
terraform apply tfplan

# Get the outputs
echo ""
echo "📊 Deployment completed! Here are the important details:"
echo "=================================================="

echo "🌐 Name Servers (Update these at your domain registrar):"
terraform output -raw name_servers | tr -d '[]"' | tr ',' '\n' | sed 's/^/   /'

echo ""
echo "🔒 SSL Certificate Status:"
terraform output certificate_status

echo ""
echo "📋 Next Steps:"
echo "1. Update nameservers at your domain registrar with the values above"
echo "2. Wait 5-10 minutes for DNS propagation"
echo "3. Test your domain: https://robertconsulting.net"
echo "4. Test WWW subdomain: https://www.robertconsulting.net"

echo ""
echo "⏱️  Expected Timeline:"
echo "   - DNS Propagation: 5-60 minutes"
echo "   - SSL Certificate: 5-10 minutes"
echo "   - Full deployment: 15-20 minutes"

echo ""
echo "🔍 To monitor progress:"
echo "   terraform output certificate_status"
echo "   terraform output name_servers"

echo ""
echo "✅ Domain deployment script completed!"


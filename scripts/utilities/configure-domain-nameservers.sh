#!/bin/bash

# Configure nameservers for robertconsulting.net domain
echo "🌐 Configuring Domain Nameservers"
echo "================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check current domain registration..."
aws route53domains list-domains --region us-east-1

echo ""
echo "🔍 Step 2: Get Route 53 hosted zone nameservers..."
HOSTED_ZONE_ID=$(terraform output -raw hosted_zone_id)
echo "Hosted Zone ID: $HOSTED_ZONE_ID"

echo ""
echo "Route 53 Nameservers:"
terraform output name_servers

echo ""
echo "🔍 Step 3: Check current domain nameservers..."
aws route53domains get-domain-detail --domain-name robertconsulting.net --region us-east-1 --query 'Nameservers' --output table

echo ""
echo "🔧 Step 4: Update domain nameservers..."
echo "This will update the nameservers for robertconsulting.net to use Route 53"

# Get the nameservers from Terraform output
NAMESERVERS=$(terraform output -json name_servers | jq -r '.[]' | tr '\n' ' ')

echo "Setting nameservers to: $NAMESERVERS"

# Update the domain nameservers
aws route53domains update-domain-nameservers \
    --domain-name robertconsulting.net \
    --nameservers Name=$NAMESERVERS \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Nameservers updated successfully!"
else
    echo "❌ Failed to update nameservers"
    echo "You may need to update them manually in the AWS Console"
fi

echo ""
echo "⏱️  Step 5: Wait for DNS propagation (5-10 minutes)..."
echo "This can take up to 48 hours for full propagation"

echo ""
echo "🔍 Step 6: Test nameserver resolution..."
echo "Testing in 30 seconds..."
sleep 30

nslookup -type=NS robertconsulting.net 8.8.8.8

echo ""
echo "📋 Next Steps:"
echo "1. Wait 5-60 minutes for DNS propagation"
echo "2. Test domain resolution: nslookup robertconsulting.net"
echo "3. Once working, deploy SES: terraform apply"
echo "4. Test email: ./test-email.sh"

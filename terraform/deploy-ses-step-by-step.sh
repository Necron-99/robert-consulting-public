#!/bin/bash

# Deploy SES step by step to avoid dependency issues
echo "📧 Deploying SES Step by Step"
echo "============================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Deploy SES domain identity..."
terraform apply -target=aws_ses_domain_identity.main -auto-approve

echo ""
echo "🔍 Step 2: Deploy SES domain DKIM..."
terraform apply -target=aws_ses_domain_dkim.main -auto-approve

echo ""
echo "🔍 Step 3: Deploy Route 53 DNS records for SES..."
terraform apply -target=aws_route53_record.ses_verification -auto-approve
terraform apply -target=aws_route53_record.ses_dkim -auto-approve

echo ""
echo "⏱️  Step 4: Wait for DNS propagation (30 seconds)..."
sleep 30

echo ""
echo "🔍 Step 5: Deploy SES domain verification..."
terraform apply -target=aws_ses_domain_identity_verification.main -auto-approve

echo ""
echo "🔍 Step 6: Deploy SES email identity..."
terraform apply -target=aws_ses_email_identity.info -auto-approve

echo ""
echo "🔍 Step 7: Deploy SES configuration set..."
terraform apply -target=aws_ses_configuration_set.main -auto-approve

echo ""
echo "🔍 Step 8: Deploy SES event destination..."
terraform apply -target=aws_ses_event_destination.cloudwatch -auto-approve

echo ""
echo "✅ SES deployment complete!"
echo ""
echo "📧 Testing email functionality..."
./test-email.sh

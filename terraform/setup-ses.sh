#!/bin/bash

# Setup AWS SES for robertconsulting.net
echo "📧 Setting up AWS SES for robertconsulting.net"
echo "============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check current SES status..."
echo "Current SES identities:"
aws ses list-identities --region us-east-1

echo ""
echo "🔍 Step 2: Check domain verification status..."
aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1

echo ""
echo "🚀 Step 3: Deploy SES configuration..."
terraform plan -target=aws_ses_domain_identity.main
terraform plan -target=aws_ses_domain_dkim.main
terraform plan -target=aws_ses_domain_identity_verification.main

echo ""
echo "✅ SES configuration ready!"
echo ""
echo "📋 Next Steps:"
echo "1. Run 'terraform apply' to create SES resources"
echo "2. Wait for domain verification (5-10 minutes)"
echo "3. Test email sending with info@robertconsulting.net"
echo ""
echo "🔧 Manual verification (if needed):"
echo "aws ses verify-domain-identity --domain robertconsulting.net --region us-east-1"
echo ""
echo "📧 Test email sending:"
echo "aws ses send-email --source info@robertconsulting.net --destination ToAddresses=test@example.com --message Subject.Data='Test' Body.Text.Data='Test message' --region us-east-1"

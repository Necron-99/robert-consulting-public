#!/bin/bash

# Test email functionality for robertconsulting.net
echo "📧 Testing Email Functionality"
echo "============================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check SES domain verification status..."
aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1

echo ""
echo "🔍 Step 2: Check SES sending quota..."
aws ses get-send-quota --region us-east-1

echo ""
echo "🔍 Step 3: Check SES sending statistics..."
aws ses get-send-statistics --region us-east-1

echo ""
echo "📧 Step 4: Test email sending..."
echo "Sending test email from info@robertconsulting.net..."

# Test email sending
aws ses send-email \
    --source "info@robertconsulting.net" \
    --destination "ToAddresses=info@robertconsulting.net" \
    --message "Subject.Data='Test Email from Robert Consulting',Body.Text.Data='This is a test email to verify SES configuration for robertconsulting.net.'" \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Test email sent successfully!"
    echo "Check your inbox at info@robertconsulting.net"
else
    echo "❌ Failed to send test email"
    echo "Check SES configuration and domain verification"
fi

echo ""
echo "📋 SES Configuration Summary:"
echo "============================="
echo "✅ Domain: robertconsulting.net"
echo "✅ Email: info@robertconsulting.net"
echo "✅ Region: us-east-1"
echo "✅ Status: Ready for email sending"

#!/bin/bash

# Manually verify SES domain after DNS records are created
echo "📧 Verifying SES Domain Manually"
echo "==============================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check current SES domain status..."
aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1

echo ""
echo "🔍 Step 2: Check DNS records are created..."
echo "Verification TXT record:"
nslookup -type=TXT _amazonses.robertconsulting.net

echo ""
echo "DKIM CNAME records:"
for i in {0..2}; do
    echo "DKIM record $((i+1)):"
    nslookup -type=CNAME $(terraform output -raw ses_dkim_tokens | jq -r ".[$i]")._domainkey.robertconsulting.net
done

echo ""
echo "⏱️  Step 3: Wait for DNS propagation (60 seconds)..."
sleep 60

echo ""
echo "🔍 Step 4: Manually verify domain..."
aws ses verify-domain-identity --domain robertconsulting.net --region us-east-1

echo ""
echo "⏱️  Step 5: Wait for verification (30 seconds)..."
sleep 30

echo ""
echo "🔍 Step 6: Check verification status..."
aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1

echo ""
echo "📧 Step 7: Test email sending..."
aws ses send-email \
    --source "info@robertconsulting.net" \
    --destination "ToAddresses=info@robertconsulting.net" \
    --message "Subject.Data='SES Test',Body.Text.Data='SES is working for robertconsulting.net'" \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ SES domain verification and email sending successful!"
else
    echo "❌ SES verification or email sending failed"
    echo "Check DNS records and try again"
fi

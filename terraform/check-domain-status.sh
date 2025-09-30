#!/bin/bash

# Check Domain Status for robertconsulting.net
# This script checks the current status of the domain and infrastructure

set -e

echo "🔍 Checking Domain Status for robertconsulting.net"
echo "==============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check if domain is registered in AWS..."
aws route53domains list-domains --query 'Domains[?DomainName==`robertconsulting.net`].{DomainName:DomainName,Status:Status}' --output table

echo ""
echo "🔍 Step 2: Check Route 53 hosted zone..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | sed 's|/hostedzone/||')
if [ -n "$HOSTED_ZONE_ID" ]; then
    echo "✅ Route 53 hosted zone found: $HOSTED_ZONE_ID"
    
    echo ""
    echo "🔍 Step 3: Check DNS records in Route 53..."
    aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --query 'ResourceRecordSets[*].{Name:Name,Type:Type,Value:ResourceRecords[0].Value}' --output table
else
    echo "❌ Route 53 hosted zone not found for robertconsulting.net"
    echo "This means the domain is not yet configured in AWS"
fi

echo ""
echo "🔍 Step 4: Check CloudFront distributions..."
aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items}' --output table

echo ""
echo "🔍 Step 5: Check if domain resolves..."
if nslookup robertconsulting.net &>/dev/null; then
    echo "✅ Domain resolves: robertconsulting.net"
    nslookup robertconsulting.net
else
    echo "❌ Domain does not resolve: robertconsulting.net"
    echo "This means DNS is not properly configured"
fi

echo ""
echo "📋 Current Status Summary:"
echo "========================"
if [ -n "$HOSTED_ZONE_ID" ]; then
    echo "✅ Route 53 hosted zone: EXISTS"
else
    echo "❌ Route 53 hosted zone: MISSING"
fi

if nslookup robertconsulting.net &>/dev/null; then
    echo "✅ DNS resolution: WORKS"
else
    echo "❌ DNS resolution: FAILS"
fi

echo ""
echo "🔧 Next Steps:"
if [ -z "$HOSTED_ZONE_ID" ]; then
    echo "1. Deploy infrastructure: terraform apply"
    echo "2. Get nameservers: terraform output name_servers"
    echo "3. Update domain nameservers at your registrar"
    echo "4. Wait for DNS propagation (5-60 minutes)"
else
    echo "1. Check if nameservers are properly configured"
    echo "2. Wait for DNS propagation (5-60 minutes)"
    echo "3. Test the domain: https://robertconsulting.net"
fi

#!/bin/bash

# Diagnose DNS Issue for robertconsulting.net
# This script checks why the domain isn't resolving despite correct nameservers

set -e

echo "🔍 Diagnosing DNS Issue for robertconsulting.net"
echo "==============================================="

# Check if we're in the terraform directory
if [ ! -f "infrastructure.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Check current nameservers for robertconsulting.net..."
echo "Current nameservers:"
nslookup -type=NS robertconsulting.net

echo ""
echo "🔍 Step 2: Check if domain resolves to any IP..."
echo "Domain resolution:"
nslookup robertconsulting.net

echo ""
echo "🔍 Step 3: Check Route 53 nameservers..."
echo "Expected Route 53 nameservers:"
terraform output name_servers

echo ""
echo "🔍 Step 4: Check A records in Route 53..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | sed 's|/hostedzone/||')
if [ -n "$HOSTED_ZONE_ID" ]; then
    echo "Route 53 A records:"
    aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --query 'ResourceRecordSets[?Type==`A`].{Name:Name,Value:ResourceRecords[0].Value}' --output table
else
    echo "❌ No Route 53 hosted zone found"
fi

echo ""
echo "🔍 Step 5: Check CloudFront distribution aliases..."
aws cloudfront get-distribution --id E36DBYPHUUKB3V --query 'Distribution.DistributionConfig.Aliases.Items' --output table

echo ""
echo "🔍 Step 6: Test CloudFront directly..."
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_distribution_domain_name)
echo "Testing CloudFront domain: $CLOUDFRONT_DOMAIN"
curl -I "https://$CLOUDFRONT_DOMAIN" 2>/dev/null | head -5 || echo "❌ CloudFront not responding"

echo ""
echo "🔍 Step 7: Check certificate status..."
CERT_ARN=$(terraform output -raw certificate_arn)
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus}' --output table

echo ""
echo "📋 Diagnosis Summary:"
echo "==================="
echo "1. Nameservers: Check if they match Route 53 nameservers"
echo "2. A Records: Check if they point to CloudFront"
echo "3. CloudFront: Check if distribution is working"
echo "4. Certificate: Check if it's validated"
echo "5. Aliases: Check if CloudFront has the domain aliases"

echo ""
echo "🔧 Possible Issues:"
echo "1. Nameservers don't match Route 53"
echo "2. A records don't point to CloudFront"
echo "3. CloudFront doesn't have domain aliases configured"
echo "4. Certificate not validated"
echo "5. DNS propagation still in progress"

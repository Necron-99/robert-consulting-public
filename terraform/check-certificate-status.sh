#!/bin/bash

# Check SSL Certificate Status and Provide Solutions
echo "🔍 Checking SSL Certificate Status"
echo "================================="

# Get certificate ARN
CERT_ARN=$(terraform output -raw certificate_arn)
echo "Certificate ARN: $CERT_ARN"

echo ""
echo "🔍 Certificate Status:"
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus,ValidationMethod:ValidationMethod}' --output table

echo ""
echo "🔍 Domain Validation Options:"
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

echo ""
echo "🔍 Route 53 DNS Records:"
HOSTED_ZONE_ID=$(terraform output -raw hosted_zone_id)
aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --query 'ResourceRecordSets[?Type==`CNAME`].{Name:Name,Value:ResourceRecords[0].Value}' --output table

echo ""
echo "📋 Current Situation:"
echo "===================="
echo "✅ Route 53 hosted zone: EXISTS"
echo "✅ DNS records: CONFIGURED"
echo "✅ CloudFront distribution: DEPLOYED"
echo "❌ SSL Certificate: PENDING_VALIDATION"
echo "❌ CloudFront aliases: DISABLED (requires validated certificate)"

echo ""
echo "🔧 Solutions:"
echo "============="
echo "1. WAIT: Certificate should validate automatically (5-60 minutes)"
echo "2. MANUAL: Check if validation records are correct"
echo "3. ALTERNATIVE: Use CloudFront domain directly for now"

echo ""
echo "🌐 Current Working URLs:"
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_distribution_domain_name)
echo "  - https://$CLOUDFRONT_DOMAIN (CloudFront domain)"
echo "  - http://$CLOUDFRONT_DOMAIN (HTTP version)"

echo ""
echo "⏱️  Next Steps:"
echo "1. Wait for certificate validation (check every 5 minutes)"
echo "2. Once validated, uncomment aliases in infrastructure.tf"
echo "3. Run terraform apply to enable custom domain"

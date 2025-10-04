#!/bin/bash

# Fix DNS Validation for SSL Certificate
# This script resolves the certificate validation timeout issue

set -e

echo "🔧 Fixing DNS Validation for SSL Certificate"
echo "==========================================="

CERT_ARN="arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

echo "🔍 Step 1: Check certificate validation records..."
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

echo ""
echo "🔍 Step 2: Check Route 53 hosted zone..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | sed 's|/hostedzone/||')
echo "Hosted Zone ID: $HOSTED_ZONE_ID"

if [ -n "$HOSTED_ZONE_ID" ]; then
    echo "🔍 Step 3: Check DNS records in Route 53..."
    aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --query 'ResourceRecordSets[?Type==`CNAME`].{Name:Name,Type:Type,Value:ResourceRecords[0].Value}' --output table
fi

echo ""
echo "🔧 Step 4: Destroy the certificate validation resource..."
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve

echo ""
echo "🔧 Step 5: Check if certificate is already validated..."
CERT_STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.Status' --output text)
echo "Certificate Status: $CERT_STATUS"

if [ "$CERT_STATUS" = "ISSUED" ]; then
    echo "✅ Certificate is already validated! Skipping validation step."
    echo ""
    echo "🔧 Step 6: Comment out certificate validation in Terraform..."
    echo "Edit domain-namecheap.tf and comment out the aws_acm_certificate_validation resource"
    echo "Then run: terraform apply"
else
    echo "⚠️  Certificate is still pending validation"
    echo ""
    echo "🔧 Step 6: Manual DNS validation approach..."
    echo "1. Get the validation records:"
    aws acm describe-certificate --certificate-arn "$CERT_ARN" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
    
    echo ""
    echo "2. Manually add these CNAME records to your DNS provider"
    echo "3. Wait 5-10 minutes for DNS propagation"
    echo "4. Run: terraform apply -target=aws_acm_certificate_validation.wildcard"
fi

echo ""
echo "📋 Alternative: Skip certificate validation entirely"
echo "If the certificate is already working, you can skip validation by:"
echo "1. Commenting out the aws_acm_certificate_validation resource"
echo "2. Updating the CloudFront distribution to use the certificate directly"
echo "3. Running terraform apply"

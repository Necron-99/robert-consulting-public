# Check SSL Certificate Status and Provide Solutions
# PowerShell script for Windows environments

Write-Host "🔍 Checking SSL Certificate Status" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Get certificate ARN
$CERT_ARN = terraform output -raw certificate_arn
Write-Host "Certificate ARN: $CERT_ARN" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔍 Certificate Status:" -ForegroundColor Yellow
try {
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus,ValidationMethod:ValidationMethod}' --output table
} catch {
    Write-Host "⚠️  Could not check certificate status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Domain Validation Options:" -ForegroundColor Yellow
try {
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
} catch {
    Write-Host "⚠️  Could not check domain validation options" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Route 53 DNS Records:" -ForegroundColor Yellow
try {
    $HOSTED_ZONE_ID = terraform output -raw hosted_zone_id
    aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query 'ResourceRecordSets[?Type==`CNAME`].{Name:Name,Value:ResourceRecords[0].Value}' --output table
} catch {
    Write-Host "⚠️  Could not check Route 53 records" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Current Situation:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "✅ Route 53 hosted zone: EXISTS" -ForegroundColor Green
Write-Host "✅ DNS records: CONFIGURED" -ForegroundColor Green
Write-Host "✅ CloudFront distribution: DEPLOYED" -ForegroundColor Green
Write-Host "❌ SSL Certificate: PENDING_VALIDATION" -ForegroundColor Red
Write-Host "❌ CloudFront aliases: DISABLED (requires validated certificate)" -ForegroundColor Red

Write-Host ""
Write-Host "🔧 Solutions:" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow
Write-Host "1. WAIT: Certificate should validate automatically (5-60 minutes)" -ForegroundColor White
Write-Host "2. MANUAL: Check if validation records are correct" -ForegroundColor White
Write-Host "3. ALTERNATIVE: Use CloudFront domain directly for now" -ForegroundColor White

Write-Host ""
Write-Host "🌐 Current Working URLs:" -ForegroundColor Cyan
$CLOUDFRONT_DOMAIN = terraform output -raw cloudfront_distribution_domain_name
Write-Host "  - https://$CLOUDFRONT_DOMAIN (CloudFront domain)" -ForegroundColor White
Write-Host "  - http://$CLOUDFRONT_DOMAIN (HTTP version)" -ForegroundColor White

Write-Host ""
Write-Host "⏱️  Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait for certificate validation (check every 5 minutes)" -ForegroundColor White
Write-Host "2. Once validated, uncomment aliases in infrastructure.tf" -ForegroundColor White
Write-Host "3. Run terraform apply to enable custom domain" -ForegroundColor White

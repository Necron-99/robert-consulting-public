# Diagnose DNS Issue for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔍 Diagnosing DNS Issue for robertconsulting.net" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check current nameservers for robertconsulting.net..." -ForegroundColor Yellow
Write-Host "Current nameservers:" -ForegroundColor Cyan
nslookup -type=NS robertconsulting.net

Write-Host ""
Write-Host "🔍 Step 2: Check if domain resolves to any IP..." -ForegroundColor Yellow
Write-Host "Domain resolution:" -ForegroundColor Cyan
nslookup robertconsulting.net

Write-Host ""
Write-Host "🔍 Step 3: Check Route 53 nameservers..." -ForegroundColor Yellow
Write-Host "Expected Route 53 nameservers:" -ForegroundColor Cyan
terraform output name_servers

Write-Host ""
Write-Host "🔍 Step 4: Check A records in Route 53..." -ForegroundColor Yellow
try {
    $HOSTED_ZONE_ID = aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | ForEach-Object { $_ -replace '/hostedzone/', '' }
    if ($HOSTED_ZONE_ID) {
        Write-Host "Route 53 A records:" -ForegroundColor Cyan
        aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query 'ResourceRecordSets[?Type==`A`].{Name:Name,Value:ResourceRecords[0].Value}' --output table
    } else {
        Write-Host "❌ No Route 53 hosted zone found" -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️  Could not check Route 53 records" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 5: Check CloudFront distribution aliases..." -ForegroundColor Yellow
try {
    aws cloudfront get-distribution --id E36DBYPHUUKB3V --query 'Distribution.DistributionConfig.Aliases.Items' --output table
} catch {
    Write-Host "⚠️  Could not check CloudFront aliases" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 6: Test CloudFront directly..." -ForegroundColor Yellow
$CLOUDFRONT_DOMAIN = terraform output -raw cloudfront_distribution_domain_name
Write-Host "Testing CloudFront domain: $CLOUDFRONT_DOMAIN" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://$CLOUDFRONT_DOMAIN" -Method Head -TimeoutSec 10
    Write-Host "✅ CloudFront responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ CloudFront not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔍 Step 7: Check certificate status..." -ForegroundColor Yellow
try {
    $CERT_ARN = terraform output -raw certificate_arn
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus}' --output table
} catch {
    Write-Host "⚠️  Could not check certificate status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Diagnosis Summary:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "1. Nameservers: Check if they match Route 53 nameservers" -ForegroundColor White
Write-Host "2. A Records: Check if they point to CloudFront" -ForegroundColor White
Write-Host "3. CloudFront: Check if distribution is working" -ForegroundColor White
Write-Host "4. Certificate: Check if it's validated" -ForegroundColor White
Write-Host "5. Aliases: Check if CloudFront has the domain aliases" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Possible Issues:" -ForegroundColor Yellow
Write-Host "1. Nameservers don't match Route 53" -ForegroundColor White
Write-Host "2. A records don't point to CloudFront" -ForegroundColor White
Write-Host "3. CloudFront doesn't have domain aliases configured" -ForegroundColor White
Write-Host "4. Certificate not validated" -ForegroundColor White
Write-Host "5. DNS propagation still in progress" -ForegroundColor White

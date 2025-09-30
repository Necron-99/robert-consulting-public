# Test SSL Certificate and CloudFront Setup
# This script tests the SSL certificate and CloudFront configuration

Write-Host "🧪 Testing SSL Certificate and CloudFront Setup" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "domain-namecheap.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Checking Certificate Status..." -ForegroundColor Yellow

# Get certificate details
try {
    $certArn = terraform output -raw certificate_arn
    Write-Host "📋 Certificate ARN: $certArn" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error getting certificate ARN" -ForegroundColor Red
    exit 1
}

# Check certificate status
$certStatus = aws acm describe-certificate --certificate-arn $certArn --region us-east-1 --query 'Certificate.Status' --output text
Write-Host "🔒 Certificate Status: $certStatus" -ForegroundColor Cyan

if ($certStatus -ne "ISSUED") {
    Write-Host "❌ Certificate is not issued yet. Status: $certStatus" -ForegroundColor Red
    Write-Host "Please wait for certificate validation to complete." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Certificate is issued and ready!" -ForegroundColor Green

Write-Host ""
Write-Host "🔍 Step 2: Checking CloudFront Distribution..." -ForegroundColor Yellow

# Get CloudFront distribution details
try {
    $distributionId = terraform output -raw cloudfront_distribution_id
    Write-Host "📋 Distribution ID: $distributionId" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error getting CloudFront distribution ID" -ForegroundColor Red
    exit 1
}

# Check CloudFront status
$distStatus = aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status' --output text
Write-Host "🌐 CloudFront Status: $distStatus" -ForegroundColor Cyan

if ($distStatus -ne "Deployed") {
    Write-Host "⚠️  CloudFront is still deploying. Status: $distStatus" -ForegroundColor Yellow
    Write-Host "This may take 10-15 minutes. You can check status with:" -ForegroundColor White
    Write-Host "aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status' --output text" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🔍 Step 3: Testing HTTPS URLs..." -ForegroundColor Yellow

# Get CloudFront domain
try {
    $cloudfrontDomain = terraform output -raw cloudfront_distribution_domain_name
    Write-Host "📋 CloudFront Domain: $cloudfrontDomain" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error getting CloudFront domain" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🧪 Testing URLs (these should work with HTTPS):" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Test CloudFront domain
Write-Host "1. CloudFront HTTPS:" -ForegroundColor White
Write-Host "   https://$cloudfrontDomain" -ForegroundColor Gray
Write-Host "   Testing..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "https://$cloudfrontDomain" -Method Head -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ CloudFront HTTPS working" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  CloudFront HTTPS returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  CloudFront HTTPS not responding yet (may still be deploying)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "2. Custom Domain (if DNS is configured):" -ForegroundColor White
Write-Host "   https://robertconsulting.net" -ForegroundColor Gray
Write-Host "   https://www.robertconsulting.net" -ForegroundColor Gray
Write-Host ""
Write-Host "   To test these, you need to:" -ForegroundColor Yellow
Write-Host "   - Add A record at Namecheap: robertconsulting.net → CloudFront IP" -ForegroundColor White
Write-Host "   - Keep existing CNAME: www.robertconsulting.net → dpm4biqgmoi9l.cloudfront.net" -ForegroundColor White

Write-Host ""
Write-Host "🔍 Step 4: SSL Certificate Details..." -ForegroundColor Yellow

# Get certificate details
Write-Host "📋 Certificate Information:" -ForegroundColor Cyan
aws acm describe-certificate --certificate-arn $certArn --region us-east-1 --query 'Certificate.{DomainName:DomainName,SubjectAlternativeNames:SubjectAlternativeNames,Status:Status,NotBefore:NotBefore,NotAfter:NotAfter}' --output table

Write-Host ""
Write-Host "🔍 Step 5: DNS Configuration for Namecheap..." -ForegroundColor Yellow

Write-Host "📋 Add these records at Namecheap:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. A Record (for root domain):" -ForegroundColor White
Write-Host "   Name: @ (or robertconsulting.net)" -ForegroundColor Gray
Write-Host "   Value: [Get CloudFront IP from AWS Console]" -ForegroundColor Gray
Write-Host "   TTL: 300" -ForegroundColor Gray
Write-Host ""
Write-Host "2. CNAME Record (keep existing):" -ForegroundColor White
Write-Host "   Name: www" -ForegroundColor Gray
Write-Host "   Value: dpm4biqgmoi9l.cloudfront.net" -ForegroundColor Gray
Write-Host "   TTL: 300" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Optional CNAME Records (for subdomains):" -ForegroundColor White
Write-Host "   Name: api" -ForegroundColor Gray
Write-Host "   Value: dpm4biqgmoi9l.cloudfront.net" -ForegroundColor Gray
Write-Host "   TTL: 300" -ForegroundColor Gray

Write-Host ""
Write-Host "🔍 Step 6: Testing Commands..." -ForegroundColor Yellow

Write-Host "📋 Manual Testing Commands:" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Test CloudFront directly:" -ForegroundColor White
Write-Host "curl -I https://$cloudfrontDomain" -ForegroundColor Gray
Write-Host ""
Write-Host "# Test with custom domain (after DNS setup):" -ForegroundColor White
Write-Host "curl -I https://robertconsulting.net" -ForegroundColor Gray
Write-Host "curl -I https://www.robertconsulting.net" -ForegroundColor Gray
Write-Host ""
Write-Host "# Check SSL certificate details:" -ForegroundColor White
Write-Host "openssl s_client -connect robertconsulting.net:443 -servername robertconsulting.net" -ForegroundColor Gray
Write-Host ""
Write-Host "# Test from different locations:" -ForegroundColor White
Write-Host "nslookup robertconsulting.net" -ForegroundColor Gray
Write-Host "dig robertconsulting.net" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ SSL Certificate Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Add DNS records at Namecheap (shown above)" -ForegroundColor White
Write-Host "2. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test your domains: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Monitor CloudFront deployment status" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To check CloudFront status:" -ForegroundColor Cyan
Write-Host "aws cloudfront get-distribution --id $distributionId --query 'Distribution.Status' --output text" -ForegroundColor Gray
Write-Host ""
Write-Host "🎉 Your SSL certificate is ready and CloudFront is being updated!" -ForegroundColor Green


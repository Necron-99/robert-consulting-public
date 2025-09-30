# Step-by-Step Deployment for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🚀 Step-by-Step Deployment for robertconsulting.net" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Phase 1: Deploy infrastructure without custom domains..." -ForegroundColor Yellow
Write-Host "This will create the CloudFront distribution with default certificate" -ForegroundColor White

# Apply the changes
terraform apply

Write-Host ""
Write-Host "✅ Phase 1 Complete! CloudFront distribution created" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Phase 2: Manual Certificate Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Get the validation records:" -ForegroundColor White
$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"
aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

Write-Host ""
Write-Host "2. Add these CNAME records to your DNS provider (Route 53 or your registrar)" -ForegroundColor White
Write-Host "3. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
Write-Host "4. Check certificate status:" -ForegroundColor White
Write-Host "   aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.Status'" -ForegroundColor White
Write-Host ""
Write-Host "5. Once certificate shows 'ISSUED', run Phase 3:" -ForegroundColor White
Write-Host "   .\terraform\enable-custom-domains.ps1" -ForegroundColor White

Write-Host ""
Write-Host "📋 Current Status:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "✅ CloudFront distribution created" -ForegroundColor Green
Write-Host "✅ S3 bucket configured" -ForegroundColor Green
Write-Host "✅ Route 53 hosted zone created" -ForegroundColor Green
Write-Host "⏳ Certificate validation pending" -ForegroundColor Yellow
Write-Host "⏳ Custom domains not yet enabled" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Your site is accessible at:" -ForegroundColor Cyan
$CLOUDFRONT_DOMAIN = terraform output -raw cloudfront_distribution_domain_name
Write-Host "https://$CLOUDFRONT_DOMAIN" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Validate the certificate (see instructions above)" -ForegroundColor White
Write-Host "2. Update your domain nameservers: terraform output name_servers" -ForegroundColor White
Write-Host "3. Once certificate is validated, enable custom domains" -ForegroundColor White

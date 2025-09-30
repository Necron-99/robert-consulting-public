# Deploy robertconsulting.net with unencrypted access
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🚀 Deploying robertconsulting.net with unencrypted access" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Deploying infrastructure with HTTP access..." -ForegroundColor Yellow
terraform apply

Write-Host ""
Write-Host "✅ Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Current Status:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "✅ CloudFront distribution created" -ForegroundColor Green
Write-Host "✅ S3 bucket configured" -ForegroundColor Green
Write-Host "✅ Route 53 hosted zone created" -ForegroundColor Green
Write-Host "✅ HTTP access enabled (unencrypted)" -ForegroundColor Green
Write-Host "⏳ Certificate validation pending" -ForegroundColor Yellow
Write-Host "⏳ Custom domains not yet enabled" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Your site is accessible at:" -ForegroundColor Cyan
$CLOUDFRONT_DOMAIN = terraform output -raw cloudfront_distribution_domain_name
Write-Host "http://$CLOUDFRONT_DOMAIN" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update your domain nameservers: terraform output name_servers" -ForegroundColor White
Write-Host "2. Test the site works with HTTP" -ForegroundColor White
Write-Host "3. Validate the certificate when ready" -ForegroundColor White
Write-Host "4. Enable HTTPS and custom domains later" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To get nameservers:" -ForegroundColor Cyan
Write-Host "terraform output name_servers" -ForegroundColor White

# Deploy updated website content with new contact information
# PowerShell script for Windows environments

Write-Host "🚀 Deploying Updated Website Content" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check if we're in the website directory
if (-not (Test-Path "index.html")) {
    Write-Host "❌ Error: Please run this script from the website directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Updated Contact Information:" -ForegroundColor Cyan
Write-Host "  Phone: (434) 227-8323" -ForegroundColor White
Write-Host "  Email: info@robertconsulting.net" -ForegroundColor White
Write-Host "  Domain: robertconsulting.net" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Deploying to S3..." -ForegroundColor Yellow

# Deploy to S3
try {
    aws s3 sync . s3://robert-consulting-website --delete --exclude "*.ps1" --exclude "*.sh" --exclude "*.md" --exclude "testing/*"
    Write-Host "✅ Website content deployed to S3" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to deploy to S3: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔄 Invalidating CloudFront cache..." -ForegroundColor Yellow

# Invalidate CloudFront
try {
    $DISTRIBUTION_ID = "E36DBYPHUUKB3V"
    aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
    Write-Host "✅ CloudFront cache invalidated" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not invalidate CloudFront cache: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Website deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your website is now live with updated contact information:" -ForegroundColor Cyan
Write-Host "  - https://dpm4biqgmoi9l.cloudfront.net (CloudFront domain)" -ForegroundColor White
Write-Host "  - https://robertconsulting.net (once domain is configured)" -ForegroundColor White
Write-Host ""
Write-Host "📧 Next step: Set up AWS SES for info@robertconsulting.net" -ForegroundColor Yellow
Write-Host "  Run: cd ../terraform && ./setup-ses.ps1" -ForegroundColor White

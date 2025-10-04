# Update Version Information and Deploy
# PowerShell script to fix version synchronization

Write-Host "🔄 Updating Version Information" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if we're in the website directory
if (-not (Test-Path "index.html")) {
    Write-Host "❌ Error: Please run this script from the website directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Version Information:" -ForegroundColor Cyan
Write-Host "  Version: 1.0.1" -ForegroundColor White
Write-Host "  Build: 2025-01-30" -ForegroundColor White
Write-Host "  Release: stable" -ForegroundColor White
Write-Host "  Domain: robertconsulting.net" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Deploying updated version files to S3..." -ForegroundColor Yellow

# Deploy to S3
try {
    aws s3 sync . s3://robert-consulting-website --delete --exclude "*.ps1" --exclude "*.sh" --exclude "*.md" --exclude "testing/*"
    Write-Host "✅ Version files deployed to S3" -ForegroundColor Green
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
Write-Host "✅ Version synchronization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your website now shows:" -ForegroundColor Cyan
Write-Host "  - Version: 1.0.1" -ForegroundColor White
Write-Host "  - Build: 2025-01-30" -ForegroundColor White
Write-Host "  - Domain: robertconsulting.net" -ForegroundColor White
Write-Host ""
Write-Host "📝 Changes include:" -ForegroundColor Yellow
Write-Host "  - Fixed domain configuration" -ForegroundColor White
Write-Host "  - Updated CloudFront aliases and SSL" -ForegroundColor White
Write-Host "  - Resolved version number synchronization" -ForegroundColor White
Write-Host "  - Updated contact information" -ForegroundColor White"
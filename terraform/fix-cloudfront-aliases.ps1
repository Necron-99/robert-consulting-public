# Fix CloudFront aliases for robertconsulting.net
# PowerShell script for Windows environments

Write-Host "🔧 Fixing CloudFront aliases for robertconsulting.net" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Current CloudFront configuration:" -ForegroundColor Yellow
try {
    aws cloudfront get-distribution --id E36DBYPHUUKB3V --query 'Distribution.DistributionConfig.Aliases.Items' --output table
} catch {
    Write-Host "⚠️  Could not check current CloudFront aliases" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Applying Terraform changes..." -ForegroundColor Yellow
terraform plan

Write-Host ""
Write-Host "✅ Changes planned. Run 'terraform apply' to apply them." -ForegroundColor Green
Write-Host ""
Write-Host "After applying, your domain should work at:" -ForegroundColor Cyan
Write-Host "  - https://robertconsulting.net" -ForegroundColor White
Write-Host "  - https://www.robertconsulting.net" -ForegroundColor White

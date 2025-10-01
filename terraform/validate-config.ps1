# Validate Terraform Configuration
# This script validates the Terraform configuration after removing duplicates

Write-Host "🔍 Validating Terraform Configuration..." -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "domain-namecheap.tf")) {
    Write-Host "❌ Error: domain-namecheap.tf not found" -ForegroundColor Red
    Write-Host "Please run this script from the terraform directory" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: infrastructure.tf not found" -ForegroundColor Red
    Write-Host "Please run this script from the terraform directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Required files found" -ForegroundColor Green

# Check for duplicate files
$duplicateFiles = @("domain.tf", "providers.tf")
foreach ($file in $duplicateFiles) {
    if (Test-Path $file) {
        Write-Host "⚠️  Warning: $file still exists (should be removed)" -ForegroundColor Yellow
    }
}

# Validate Terraform configuration
Write-Host "🔧 Running terraform init..." -ForegroundColor Cyan
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: terraform init failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ terraform init successful" -ForegroundColor Green

# Validate configuration
Write-Host "🔍 Running terraform validate..." -ForegroundColor Cyan
terraform validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: terraform validate failed" -ForegroundColor Red
    Write-Host "Configuration has errors that need to be fixed" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ terraform validate successful" -ForegroundColor Green

# Show current configuration summary
Write-Host ""
Write-Host "📊 Configuration Summary:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

Write-Host "📁 Active Files:" -ForegroundColor White
Get-ChildItem -Name "*.tf" | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "🎯 Ready for SSL Certificate Setup:" -ForegroundColor Green
Write-Host "Run one of these scripts:" -ForegroundColor White
Write-Host "   .\update-current-cloudfront.ps1" -ForegroundColor Gray
Write-Host "   .\update-current-cloudfront.bat" -ForegroundColor Gray
Write-Host "   ./update-current-cloudfront.sh" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ Terraform configuration is valid!" -ForegroundColor Green

<<<<<<< HEAD

=======
>>>>>>> a5db33b (Lots of changes.)

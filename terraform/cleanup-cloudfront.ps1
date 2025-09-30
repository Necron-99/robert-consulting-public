# Cleanup Unused CloudFront Distributions
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🧹 Cleaning Up Unused CloudFront Distributions" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: List all CloudFront distributions..." -ForegroundColor Yellow
aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items,Comment:Comment}' --output table

Write-Host ""
Write-Host "🔍 Step 2: Check Terraform state for CloudFront distributions..." -ForegroundColor Yellow
terraform state list | Select-String "cloudfront"

Write-Host ""
Write-Host "🔍 Step 3: Identify distributions in Terraform state..." -ForegroundColor Yellow
Write-Host "Current Terraform-managed distributions:" -ForegroundColor Cyan
terraform state list | Select-String "cloudfront" | ForEach-Object {
    $resource = $_.Line
    Write-Host "  - $resource" -ForegroundColor White
    terraform state show $resource | Select-String -Pattern "(id|domain_name)" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
}

Write-Host ""
Write-Host "🔍 Step 4: Find distributions not in Terraform state..." -ForegroundColor Yellow
Write-Host "Checking for orphaned distributions..." -ForegroundColor Cyan

# Get all distribution IDs
$ALL_DISTRIBUTIONS = aws cloudfront list-distributions --query 'DistributionList.Items[*].Id' --output text

# Get Terraform-managed distribution IDs
$TERRAFORM_DISTRIBUTIONS = terraform state list | Select-String "cloudfront" | ForEach-Object {
    $resource = $_.Line
    terraform state show $resource | Select-String -Pattern "id " | ForEach-Object { ($_.Line -split "=")[1].Trim() -replace '"', '' }
}

Write-Host "All distributions: $ALL_DISTRIBUTIONS" -ForegroundColor White
Write-Host "Terraform-managed: $TERRAFORM_DISTRIBUTIONS" -ForegroundColor White

Write-Host ""
Write-Host "⚠️  WARNING: This will show distributions that may be orphaned" -ForegroundColor Yellow
Write-Host "Please review carefully before proceeding with deletion" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 To manually check a specific distribution:" -ForegroundColor Cyan
Write-Host "aws cloudfront get-distribution --id DISTRIBUTION_ID" -ForegroundColor White
Write-Host ""
Write-Host "🔧 To delete an unused distribution:" -ForegroundColor Cyan
Write-Host "aws cloudfront delete-distribution --id DISTRIBUTION_ID --if-match ETAG" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the distributions listed above" -ForegroundColor White
Write-Host "2. Identify which ones are no longer needed" -ForegroundColor White
Write-Host "3. Delete them manually using the AWS CLI or Console" -ForegroundColor White
Write-Host "4. Run 'terraform plan' to ensure no conflicts" -ForegroundColor White

# Remove Unused CloudFront Distributions
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🗑️  Removing Unused CloudFront Distributions" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Get all CloudFront distributions..." -ForegroundColor Yellow
$ALL_DISTRIBUTIONS = aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Comment:Comment}' --output json

Write-Host "🔍 Step 2: Get Terraform-managed distribution IDs..." -ForegroundColor Yellow
$TERRAFORM_DISTRIBUTIONS = @()
terraform state list | Select-String "cloudfront" | ForEach-Object {
    $resource = $_.Line
    $DIST_ID = terraform state show $resource | Select-String -Pattern "id " | ForEach-Object { ($_.Line -split "=")[1].Trim() -replace '"', '' }
    if ($DIST_ID) {
        $TERRAFORM_DISTRIBUTIONS += $DIST_ID
    }
}

Write-Host "Terraform-managed distributions: $($TERRAFORM_DISTRIBUTIONS -join ' ')" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔍 Step 3: Find orphaned distributions..." -ForegroundColor Yellow
$ORPHANED_DISTRIBUTIONS = @()

# Parse the JSON to find distributions not in Terraform
$ALL_DISTRIBUTIONS | ConvertFrom-Json | Where-Object { $_.Status -eq "Deployed" } | ForEach-Object {
    $DIST_ID = $_.Id
    if ($TERRAFORM_DISTRIBUTIONS -notcontains $DIST_ID) {
        Write-Host "Found orphaned distribution: $DIST_ID" -ForegroundColor Yellow
        $ORPHANED_DISTRIBUTIONS += $DIST_ID
    }
}

if ($ORPHANED_DISTRIBUTIONS.Count -eq 0) {
    Write-Host "✅ No orphaned distributions found" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "⚠️  Found orphaned distributions: $($ORPHANED_DISTRIBUTIONS -join ' ')" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔍 Step 4: Show details of orphaned distributions..." -ForegroundColor Yellow
foreach ($DIST_ID in $ORPHANED_DISTRIBUTIONS) {
    Write-Host "Distribution ID: $DIST_ID" -ForegroundColor Cyan
    aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items,Comment:Comment,LastModifiedTime:LastModifiedTime}' --output table
    Write-Host ""
}

Write-Host "⚠️  WARNING: These distributions will be deleted!" -ForegroundColor Red
Write-Host "Please review the details above before proceeding." -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    $confirmation = Read-Host "Do you want to proceed with deletion? (y/N)"
    if ($confirmation -notmatch '^[Yy]$') {
        Write-Host "❌ Deletion cancelled" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🔧 Step 5: Deleting orphaned distributions..." -ForegroundColor Yellow
foreach ($DIST_ID in $ORPHANED_DISTRIBUTIONS) {
    Write-Host "Deleting distribution: $DIST_ID" -ForegroundColor Yellow
    
    # Get the ETag for the distribution
    $ETAG = aws cloudfront get-distribution --id $DIST_ID --query 'ETag' --output text
    
    # Disable the distribution first
    Write-Host "Disabling distribution: $DIST_ID" -ForegroundColor Yellow
    aws cloudfront get-distribution-config --id $DIST_ID --query 'DistributionConfig' --output json | Out-File -FilePath "dist-config.json" -Encoding UTF8
    $config = Get-Content "dist-config.json" | ConvertFrom-Json
    $config.Enabled = $false
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath "dist-config-disabled.json" -Encoding UTF8
    
    # Update the distribution to disable it
    aws cloudfront update-distribution --id $DIST_ID --distribution-config file://dist-config-disabled.json --if-match $ETAG
    
    # Wait for the distribution to be disabled
    Write-Host "Waiting for distribution to be disabled..." -ForegroundColor Yellow
    aws cloudfront wait distribution-deployed --id $DIST_ID
    
    # Delete the distribution
    Write-Host "Deleting distribution: $DIST_ID" -ForegroundColor Yellow
    aws cloudfront delete-distribution --id $DIST_ID --if-match $ETAG
    
    Write-Host "✅ Deleted distribution: $DIST_ID" -ForegroundColor Green
}

# Clean up temporary files
Remove-Item -Path "dist-config.json" -ErrorAction SilentlyContinue
Remove-Item -Path "dist-config-disabled.json" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Run 'terraform plan' to ensure no conflicts" -ForegroundColor White
Write-Host "2. Run 'terraform apply' to deploy current configuration" -ForegroundColor White

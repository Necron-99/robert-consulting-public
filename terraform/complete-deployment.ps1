# Complete the deployment without certificate validation
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🚀 Completing Deployment to robertconsulting.net" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Step 1: Destroy the problematic certificate validation..." -ForegroundColor Yellow
try {
    terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve
} catch {
    Write-Host "⚠️  Certificate validation destroy failed or already destroyed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Step 2: Plan the deployment..." -ForegroundColor Yellow
terraform plan

Write-Host ""
Write-Host "🔧 Step 3: Apply the changes..." -ForegroundColor Yellow
terraform apply

Write-Host ""
Write-Host "✅ Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update your domain nameservers to point to Route 53" -ForegroundColor White
Write-Host "2. Wait 5-60 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test your domain: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Test WWW subdomain: https://www.robertconsulting.net" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To get nameservers:" -ForegroundColor Cyan
Write-Host "terraform output name_servers" -ForegroundColor White

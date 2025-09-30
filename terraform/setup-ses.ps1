# Setup AWS SES for robertconsulting.net
# PowerShell script for Windows environments

Write-Host "📧 Setting up AWS SES for robertconsulting.net" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check current SES status..." -ForegroundColor Yellow
Write-Host "Current SES identities:" -ForegroundColor Cyan
try {
    aws ses list-identities --region us-east-1
} catch {
    Write-Host "⚠️  Could not list SES identities" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 2: Check domain verification status..." -ForegroundColor Yellow
try {
    aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1
} catch {
    Write-Host "⚠️  Could not check domain verification" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Step 3: Deploy SES configuration..." -ForegroundColor Yellow
terraform plan -target=aws_ses_domain_identity.main
terraform plan -target=aws_ses_domain_dkim.main
terraform plan -target=aws_ses_domain_identity_verification.main

Write-Host ""
Write-Host "✅ SES configuration ready!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run 'terraform apply' to create SES resources" -ForegroundColor White
Write-Host "2. Wait for domain verification (5-10 minutes)" -ForegroundColor White
Write-Host "3. Test email sending with info@robertconsulting.net" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Manual verification (if needed):" -ForegroundColor Yellow
Write-Host "aws ses verify-domain-identity --domain robertconsulting.net --region us-east-1" -ForegroundColor White
Write-Host ""
Write-Host "📧 Test email sending:" -ForegroundColor Yellow
Write-Host "aws ses send-email --source info@robertconsulting.net --destination ToAddresses=test@example.com --message Subject.Data='Test' Body.Text.Data='Test message' --region us-east-1" -ForegroundColor White

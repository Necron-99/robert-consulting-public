# Deploy SES step by step to avoid dependency issues
# PowerShell script for Windows environments

Write-Host "📧 Deploying SES Step by Step" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Deploy SES domain identity..." -ForegroundColor Yellow
terraform apply -target=aws_ses_domain_identity.main -auto-approve

Write-Host ""
Write-Host "🔍 Step 2: Deploy SES domain DKIM..." -ForegroundColor Yellow
terraform apply -target=aws_ses_domain_dkim.main -auto-approve

Write-Host ""
Write-Host "🔍 Step 3: Deploy Route 53 DNS records for SES..." -ForegroundColor Yellow
terraform apply -target=aws_route53_record.ses_verification -auto-approve
terraform apply -target=aws_route53_record.ses_dkim -auto-approve

Write-Host ""
Write-Host "⏱️  Step 4: Wait for DNS propagation (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "🔍 Step 5: Deploy SES domain verification..." -ForegroundColor Yellow
terraform apply -target=aws_ses_domain_identity_verification.main -auto-approve

Write-Host ""
Write-Host "🔍 Step 6: Deploy SES email identity..." -ForegroundColor Yellow
terraform apply -target=aws_ses_email_identity.info -auto-approve

Write-Host ""
Write-Host "🔍 Step 7: Deploy SES configuration set..." -ForegroundColor Yellow
terraform apply -target=aws_ses_configuration_set.main -auto-approve

Write-Host ""
Write-Host "🔍 Step 8: Deploy SES event destination..." -ForegroundColor Yellow
terraform apply -target=aws_ses_event_destination.cloudwatch -auto-approve

Write-Host ""
Write-Host "✅ SES deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📧 Testing email functionality..." -ForegroundColor Yellow
.\test-email.ps1

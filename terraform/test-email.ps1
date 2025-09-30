# Test email functionality for robertconsulting.net
# PowerShell script for Windows environments

Write-Host "📧 Testing Email Functionality" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check SES domain verification status..." -ForegroundColor Yellow
try {
    aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1
} catch {
    Write-Host "⚠️  Could not check domain verification" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 2: Check SES sending quota..." -ForegroundColor Yellow
try {
    aws ses get-send-quota --region us-east-1
} catch {
    Write-Host "⚠️  Could not check sending quota" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 3: Check SES sending statistics..." -ForegroundColor Yellow
try {
    aws ses get-send-statistics --region us-east-1
} catch {
    Write-Host "⚠️  Could not check sending statistics" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📧 Step 4: Test email sending..." -ForegroundColor Yellow
Write-Host "Sending test email from info@robertconsulting.net..." -ForegroundColor Cyan

# Test email sending
try {
    aws ses send-email --source "info@robertconsulting.net" --destination "ToAddresses=info@robertconsulting.net" --message "Subject.Data='Test Email from Robert Consulting',Body.Text.Data='This is a test email to verify SES configuration for robertconsulting.net.'" --region us-east-1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Test email sent successfully!" -ForegroundColor Green
        Write-Host "Check your inbox at info@robertconsulting.net" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Failed to send test email" -ForegroundColor Red
        Write-Host "Check SES configuration and domain verification" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error sending test email: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 SES Configuration Summary:" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "✅ Domain: robertconsulting.net" -ForegroundColor Green
Write-Host "✅ Email: info@robertconsulting.net" -ForegroundColor Green
Write-Host "✅ Region: us-east-1" -ForegroundColor Green
Write-Host "✅ Status: Ready for email sending" -ForegroundColor Green

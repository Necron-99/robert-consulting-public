# Manually verify SES domain after DNS records are created
# PowerShell script for Windows environments

Write-Host "📧 Verifying SES Domain Manually" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check current SES domain status..." -ForegroundColor Yellow
try {
    aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1
} catch {
    Write-Host "⚠️  Could not check SES domain status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 2: Check DNS records are created..." -ForegroundColor Yellow
Write-Host "Verification TXT record:" -ForegroundColor Cyan
try {
    nslookup -type=TXT _amazonses.robertconsulting.net
} catch {
    Write-Host "⚠️  Could not check verification TXT record" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "DKIM CNAME records:" -ForegroundColor Cyan
try {
    $DKIM_TOKENS = terraform output -raw ses_dkim_tokens | ConvertFrom-Json
    for ($i = 0; $i -lt 3; $i++) {
        Write-Host "DKIM record $($i+1):" -ForegroundColor White
        $token = $DKIM_TOKENS[$i]
        nslookup -type=CNAME "$token._domainkey.robertconsulting.net"
    }
} catch {
    Write-Host "⚠️  Could not check DKIM records" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⏱️  Step 3: Wait for DNS propagation (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "🔍 Step 4: Manually verify domain..." -ForegroundColor Yellow
try {
    aws ses verify-domain-identity --domain robertconsulting.net --region us-east-1
} catch {
    Write-Host "⚠️  Could not verify domain: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⏱️  Step 5: Wait for verification (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "🔍 Step 6: Check verification status..." -ForegroundColor Yellow
try {
    aws ses get-identity-verification-attributes --identities robertconsulting.net --region us-east-1
} catch {
    Write-Host "⚠️  Could not check verification status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📧 Step 7: Test email sending..." -ForegroundColor Yellow
try {
    aws ses send-email --source "info@robertconsulting.net" --destination "ToAddresses=info@robertconsulting.net" --message "Subject.Data='SES Test',Body.Text.Data='SES is working for robertconsulting.net'" --region us-east-1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SES domain verification and email sending successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ SES verification or email sending failed" -ForegroundColor Red
        Write-Host "Check DNS records and try again" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error testing email: $($_.Exception.Message)" -ForegroundColor Red
}

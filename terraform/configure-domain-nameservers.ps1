# Configure nameservers for robertconsulting.net domain
# PowerShell script for Windows environments

Write-Host "🌐 Configuring Domain Nameservers" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check current domain registration..." -ForegroundColor Yellow
try {
    aws route53domains list-domains --region us-east-1
} catch {
    Write-Host "⚠️  Could not list domains: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 2: Get Route 53 hosted zone nameservers..." -ForegroundColor Yellow
$HOSTED_ZONE_ID = terraform output -raw hosted_zone_id
Write-Host "Hosted Zone ID: $HOSTED_ZONE_ID" -ForegroundColor Cyan

Write-Host ""
Write-Host "Route 53 Nameservers:" -ForegroundColor Cyan
terraform output name_servers

Write-Host ""
Write-Host "🔍 Step 3: Check current domain nameservers..." -ForegroundColor Yellow
try {
    aws route53domains get-domain-detail --domain-name robertconsulting.net --region us-east-1 --query 'Nameservers' --output table
} catch {
    Write-Host "⚠️  Could not get domain details: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Step 4: Update domain nameservers..." -ForegroundColor Yellow
Write-Host "This will update the nameservers for robertconsulting.net to use Route 53" -ForegroundColor Cyan

# Get the nameservers from Terraform output
$NAMESERVERS = terraform output -json name_servers | ConvertFrom-Json

Write-Host "Setting nameservers to: $($NAMESERVERS -join ', ')" -ForegroundColor Cyan

# Update the domain nameservers
try {
    $nameserverList = @()
    foreach ($ns in $NAMESERVERS) {
        $nameserverList += @{Name = $ns}
    }
    
    aws route53domains update-domain-nameservers --domain-name robertconsulting.net --nameservers $nameserverList --region us-east-1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Nameservers updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to update nameservers" -ForegroundColor Red
        Write-Host "You may need to update them manually in the AWS Console" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error updating nameservers: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to update them manually in the AWS Console" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⏱️  Step 5: Wait for DNS propagation (5-10 minutes)..." -ForegroundColor Yellow
Write-Host "This can take up to 48 hours for full propagation" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔍 Step 6: Test nameserver resolution..." -ForegroundColor Yellow
Write-Host "Testing in 30 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

try {
    nslookup -type=NS robertconsulting.net 8.8.8.8
} catch {
    Write-Host "⚠️  Could not test nameserver resolution" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait 5-60 minutes for DNS propagation" -ForegroundColor White
Write-Host "2. Test domain resolution: nslookup robertconsulting.net" -ForegroundColor White
Write-Host "3. Once working, deploy SES: terraform apply" -ForegroundColor White
Write-Host "4. Test email: .\test-email.ps1" -ForegroundColor White

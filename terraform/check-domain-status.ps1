# Check Domain Status for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔍 Checking Domain Status for robertconsulting.net" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Check if domain is registered in AWS..." -ForegroundColor Yellow
try {
    aws route53domains list-domains --query 'Domains[?DomainName==`robertconsulting.net`].{DomainName:DomainName,Status:Status}' --output table
} catch {
    Write-Host "⚠️  Could not check domain registration" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 2: Check Route 53 hosted zone..." -ForegroundColor Yellow
try {
    $HOSTED_ZONE_ID = aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | ForEach-Object { $_ -replace '/hostedzone/', '' }
    if ($HOSTED_ZONE_ID) {
        Write-Host "✅ Route 53 hosted zone found: $HOSTED_ZONE_ID" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "🔍 Step 3: Check DNS records in Route 53..." -ForegroundColor Yellow
        aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query 'ResourceRecordSets[*].{Name:Name,Type:Type,Value:ResourceRecords[0].Value}' --output table
    } else {
        Write-Host "❌ Route 53 hosted zone not found for robertconsulting.net" -ForegroundColor Red
        Write-Host "This means the domain is not yet configured in AWS" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check Route 53 hosted zone" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 4: Check CloudFront distributions..." -ForegroundColor Yellow
try {
    aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,DomainName:DomainName,Status:Status,Aliases:Aliases.Items}' --output table
} catch {
    Write-Host "⚠️  Could not check CloudFront distributions" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 5: Check if domain resolves..." -ForegroundColor Yellow
try {
    $result = nslookup robertconsulting.net 2>$null
    if ($result) {
        Write-Host "✅ Domain resolves: robertconsulting.net" -ForegroundColor Green
        nslookup robertconsulting.net
    } else {
        Write-Host "❌ Domain does not resolve: robertconsulting.net" -ForegroundColor Red
        Write-Host "This means DNS is not properly configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Domain does not resolve: robertconsulting.net" -ForegroundColor Red
    Write-Host "This means DNS is not properly configured" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Current Status Summary:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
if ($HOSTED_ZONE_ID) {
    Write-Host "✅ Route 53 hosted zone: EXISTS" -ForegroundColor Green
} else {
    Write-Host "❌ Route 53 hosted zone: MISSING" -ForegroundColor Red
}

try {
    $result = nslookup robertconsulting.net 2>$null
    if ($result) {
        Write-Host "✅ DNS resolution: WORKS" -ForegroundColor Green
    } else {
        Write-Host "❌ DNS resolution: FAILS" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ DNS resolution: FAILS" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
if (-not $HOSTED_ZONE_ID) {
    Write-Host "1. Deploy infrastructure: terraform apply" -ForegroundColor White
    Write-Host "2. Get nameservers: terraform output name_servers" -ForegroundColor White
    Write-Host "3. Update domain nameservers at your registrar" -ForegroundColor White
    Write-Host "4. Wait for DNS propagation (5-60 minutes)" -ForegroundColor White
} else {
    Write-Host "1. Check if nameservers are properly configured" -ForegroundColor White
    Write-Host "2. Wait for DNS propagation (5-60 minutes)" -ForegroundColor White
    Write-Host "3. Test the domain: https://robertconsulting.net" -ForegroundColor White
}

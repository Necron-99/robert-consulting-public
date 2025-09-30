# Deploy Domain and SSL Certificate for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🚀 Starting domain deployment for robertconsulting.net" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

# Check if AWS CLI is configured
Write-Host "🔍 Checking AWS configuration..." -ForegroundColor Yellow
try {
    $null = aws sts get-caller-identity 2>$null
    Write-Host "✅ AWS credentials verified" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: AWS CLI not configured or no valid credentials" -ForegroundColor Red
    Write-Host "Please run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Initialize Terraform if needed
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan the deployment
Write-Host "📋 Planning infrastructure changes..." -ForegroundColor Yellow
terraform plan -out=tfplan

# Ask for confirmation unless -Force is used
if (-not $Force) {
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Before proceeding, ensure you have:" -ForegroundColor Yellow
    Write-Host "   1. Ownership of robertconsulting.net domain" -ForegroundColor White
    Write-Host "   2. Access to your domain registrar to update nameservers" -ForegroundColor White
    Write-Host ""
    $confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
    
    if ($confirmation -notmatch '^[Yy]$') {
        Write-Host "❌ Deployment cancelled" -ForegroundColor Red
        exit 1
    }
}

# Apply the changes
Write-Host "🚀 Deploying infrastructure..." -ForegroundColor Green
terraform apply tfplan

# Get the outputs
Write-Host ""
Write-Host "📊 Deployment completed! Here are the important details:" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

Write-Host "🌐 Name Servers (Update these at your domain registrar):" -ForegroundColor Cyan
$nameServers = terraform output -raw name_servers
$nameServers -replace '\[|\]|"', '' -split ',' | ForEach-Object { Write-Host "   $($_.Trim())" -ForegroundColor White }

Write-Host ""
Write-Host "🔒 SSL Certificate Status:" -ForegroundColor Cyan
terraform output certificate_status

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update nameservers at your domain registrar with the values above" -ForegroundColor White
Write-Host "2. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test your domain: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Test WWW subdomain: https://www.robertconsulting.net" -ForegroundColor White

Write-Host ""
Write-Host "⏱️  Expected Timeline:" -ForegroundColor Yellow
Write-Host "   - DNS Propagation: 5-60 minutes" -ForegroundColor White
Write-Host "   - SSL Certificate: 5-10 minutes" -ForegroundColor White
Write-Host "   - Full deployment: 15-20 minutes" -ForegroundColor White

Write-Host ""
Write-Host "🔍 To monitor progress:" -ForegroundColor Yellow
Write-Host "   terraform output certificate_status" -ForegroundColor White
Write-Host "   terraform output name_servers" -ForegroundColor White

Write-Host ""
Write-Host "✅ Domain deployment script completed!" -ForegroundColor Green


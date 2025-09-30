# Update Current CloudFront Distribution with SSL Certificate
# This script updates your existing CloudFront distribution (E36DBYPHUUKB3V) with SSL certificate

param(
    [switch]$Force
)

Write-Host "🔒 Updating CloudFront Distribution with SSL Certificate" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "domain.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    Write-Host "Expected files: domain.tf, infrastructure.tf" -ForegroundColor Yellow
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

# Step 1: Create SSL Certificate
Write-Host "📜 Step 1: Creating SSL Certificate..." -ForegroundColor Cyan
Write-Host "Creating wildcard certificate for *.robertconsulting.net" -ForegroundColor White

terraform apply -target=aws_acm_certificate.wildcard -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creating SSL certificate" -ForegroundColor Red
    exit 1
}

Write-Host "✅ SSL Certificate created successfully" -ForegroundColor Green

# Step 2: Create DNS validation records
Write-Host "📜 Step 2: Creating DNS validation records..." -ForegroundColor Cyan
Write-Host "This will create Route 53 records for certificate validation" -ForegroundColor White

terraform apply -target=aws_route53_zone.main -auto-approve
terraform apply -target=aws_route53_record.cert_validation -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creating DNS validation records" -ForegroundColor Red
    exit 1
}

Write-Host "✅ DNS validation records created" -ForegroundColor Green

# Step 3: Validate certificate
Write-Host "📜 Step 3: Validating SSL Certificate..." -ForegroundColor Cyan
Write-Host "This may take 5-10 minutes..." -ForegroundColor White

terraform apply -target=aws_acm_certificate_validation.wildcard -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error validating SSL certificate" -ForegroundColor Red
    exit 1
}

Write-Host "✅ SSL Certificate validated successfully" -ForegroundColor Green

# Step 4: Update CloudFront Distribution
Write-Host "📜 Step 4: Updating CloudFront Distribution..." -ForegroundColor Cyan
Write-Host "Updating distribution E36DBYPHUUKB3V with SSL certificate" -ForegroundColor White

terraform apply -target=aws_cloudfront_distribution.website -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error updating CloudFront distribution" -ForegroundColor Red
    exit 1
}

Write-Host "✅ CloudFront distribution updated successfully" -ForegroundColor Green

# Get the outputs
Write-Host ""
Write-Host "📊 SSL Certificate Setup Completed!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Write-Host "🔒 SSL Certificate Details:" -ForegroundColor Cyan
$certStatus = terraform output -raw certificate_status
Write-Host "   Status: $certStatus" -ForegroundColor White

Write-Host ""
Write-Host "🌐 DNS Configuration for Namecheap:" -ForegroundColor Cyan
Write-Host "You need to add these records at Namecheap:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. A Record:" -ForegroundColor White
Write-Host "   Name: @ (or robertconsulting.net)" -ForegroundColor Gray
Write-Host "   Value: [CloudFront IP - get from AWS Console]" -ForegroundColor Gray
Write-Host ""
Write-Host "2. CNAME Record (keep existing):" -ForegroundColor White
Write-Host "   Name: www" -ForegroundColor Gray
Write-Host "   Value: dpm4biqgmoi9l.cloudfront.net" -ForegroundColor Gray
Write-Host ""
Write-Host "3. CNAME Record (optional for subdomains):" -ForegroundColor White
Write-Host "   Name: api (or any subdomain)" -ForegroundColor Gray
Write-Host "   Value: dpm4biqgmoi9l.cloudfront.net" -ForegroundColor Gray

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Add the DNS records above at Namecheap" -ForegroundColor White
Write-Host "2. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test HTTPS: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Test WWW: https://www.robertconsulting.net" -ForegroundColor White

Write-Host ""
Write-Host "🔍 To monitor certificate status:" -ForegroundColor Yellow
Write-Host "   terraform output certificate_status" -ForegroundColor White

Write-Host ""
Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "- Your current CNAME setup will continue working" -ForegroundColor White
Write-Host "- SSL certificate covers *.robertconsulting.net" -ForegroundColor White
Write-Host "- No downtime during this process" -ForegroundColor White
Write-Host "- You can test HTTPS immediately after DNS updates" -ForegroundColor White

Write-Host ""
Write-Host "✅ CloudFront SSL update completed!" -ForegroundColor Green


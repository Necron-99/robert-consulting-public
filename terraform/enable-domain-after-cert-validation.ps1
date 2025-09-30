# Enable domain aliases after certificate validation
# PowerShell script for Windows environments

Write-Host "🔧 Enabling Domain Aliases After Certificate Validation" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

# Check certificate status
$CERT_ARN = terraform output -raw certificate_arn
$CERT_STATUS = aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text

Write-Host "🔍 Certificate Status: $CERT_STATUS" -ForegroundColor Cyan

if ($CERT_STATUS -ne "ISSUED") {
    Write-Host "❌ Certificate is not yet validated. Current status: $CERT_STATUS" -ForegroundColor Red
    Write-Host "⏱️  Please wait for certificate validation and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To check status manually:" -ForegroundColor Cyan
    Write-Host "aws acm describe-certificate --certificate-arn `"$CERT_ARN`" --region us-east-1 --query 'Certificate.Status' --output text" -ForegroundColor White
    exit 1
}

Write-Host "✅ Certificate is validated! Proceeding with domain setup..." -ForegroundColor Green

# Uncomment aliases in infrastructure.tf
Write-Host "🔧 Enabling aliases in infrastructure.tf..." -ForegroundColor Yellow
$content = Get-Content "infrastructure.tf" -Raw
$content = $content -replace '# aliases = \["robertconsulting\.net", "www\.robertconsulting\.net"\]', 'aliases = ["robertconsulting.net", "www.robertconsulting.net"]'
Set-Content "infrastructure.tf" $content

# Update viewer certificate to use the validated certificate
Write-Host "🔧 Updating viewer certificate to use validated certificate..." -ForegroundColor Yellow
$content = Get-Content "infrastructure.tf" -Raw
$content = $content -replace 'cloudfront_default_certificate = true', "acm_certificate_arn = `"$CERT_ARN`""
$content = $content -replace 'ssl_support_method = "sni-only"', 'ssl_support_method = "sni-only"`n    minimum_protocol_version = "TLSv1.2_2021"'
Set-Content "infrastructure.tf" $content

Write-Host "🚀 Applying changes..." -ForegroundColor Yellow
terraform plan

Write-Host ""
Write-Host "✅ Changes ready to apply!" -ForegroundColor Green
Write-Host "Run 'terraform apply' to enable your domain." -ForegroundColor Cyan
Write-Host ""
Write-Host "After applying, your domain will work at:" -ForegroundColor Cyan
Write-Host "  - https://robertconsulting.net" -ForegroundColor White
Write-Host "  - https://www.robertconsulting.net" -ForegroundColor White

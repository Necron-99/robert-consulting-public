# Enable Custom Domains for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔧 Enabling Custom Domains for robertconsulting.net" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

Write-Host "🔍 Step 1: Check certificate status..." -ForegroundColor Yellow
$CERT_STATUS = aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text
Write-Host "Certificate Status: $CERT_STATUS" -ForegroundColor Cyan

if ($CERT_STATUS -ne "ISSUED") {
    Write-Host "❌ Certificate is not yet validated. Status: $CERT_STATUS" -ForegroundColor Red
    Write-Host "Please validate the certificate first by adding the DNS validation records." -ForegroundColor Yellow
    Write-Host "Run: aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table" -ForegroundColor White
    exit 1
}

Write-Host "✅ Certificate is validated! Proceeding with custom domain setup..." -ForegroundColor Green

Write-Host ""
Write-Host "🔧 Step 2: Update CloudFront configuration to use custom certificate..." -ForegroundColor Yellow
# Update the infrastructure.tf to use the certificate and enable aliases
(Get-Content infrastructure.tf) -replace 'cloudfront_default_certificate = true', 'acm_certificate_arn = aws_acm_certificate.wildcard.arn' | Set-Content infrastructure.tf
(Get-Content infrastructure.tf) -replace 'minimum_protocol_version        = "TLSv1.2_2021"', 'ssl_support_method       = "sni-only"`n    minimum_protocol_version = "TLSv1.2_2021"' | Set-Content infrastructure.tf
(Get-Content infrastructure.tf) -replace '# aliases = \["robertconsulting.net", "www.robertconsulting.net"\]  # Commented out until certificate is validated', 'aliases = ["robertconsulting.net", "www.robertconsulting.net"]' | Set-Content infrastructure.tf

Write-Host ""
Write-Host "🔧 Step 3: Apply the changes..." -ForegroundColor Yellow
terraform apply

Write-Host ""
Write-Host "✅ Custom domains enabled!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update your domain nameservers: terraform output name_servers" -ForegroundColor White
Write-Host "2. Wait 5-60 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test your domain: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Test WWW subdomain: https://www.robertconsulting.net" -ForegroundColor White

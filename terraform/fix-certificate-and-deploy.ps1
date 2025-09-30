# Fix Certificate and Deploy robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔧 Fixing Certificate and Deploying robertconsulting.net" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

Write-Host "🔍 Step 1: Check certificate status..." -ForegroundColor Yellow
$CERT_STATUS = aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text
Write-Host "Certificate Status: $CERT_STATUS" -ForegroundColor Cyan

if ($CERT_STATUS -eq "ISSUED") {
    Write-Host "✅ Certificate is already validated!" -ForegroundColor Green
    Write-Host "🔧 Updating CloudFront to use the certificate..." -ForegroundColor Yellow
    
    # Update the infrastructure.tf to use the certificate
    (Get-Content infrastructure.tf) -replace 'cloudfront_default_certificate = true', 'acm_certificate_arn = aws_acm_certificate.wildcard.arn' | Set-Content infrastructure.tf
    (Get-Content infrastructure.tf) -replace 'minimum_protocol_version        = "TLSv1.2_2021"', 'ssl_support_method       = "sni-only"`n    minimum_protocol_version = "TLSv1.2_2021"' | Set-Content infrastructure.tf
    
    Write-Host "🔧 Applying changes with validated certificate..." -ForegroundColor Yellow
    terraform apply
} else {
    Write-Host "⚠️  Certificate is still pending validation" -ForegroundColor Yellow
    Write-Host "🔧 Deploying with CloudFront default certificate first..." -ForegroundColor Yellow
    
    # Deploy with default certificate
    terraform apply
    
    Write-Host ""
    Write-Host "📋 Manual Certificate Validation Steps:" -ForegroundColor Cyan
    Write-Host "1. Get the validation records:" -ForegroundColor White
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
    
    Write-Host ""
    Write-Host "2. Add these CNAME records to your DNS provider" -ForegroundColor White
    Write-Host "3. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
    Write-Host "4. Check certificate status:" -ForegroundColor White
    Write-Host "   aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1 --query 'Certificate.Status'" -ForegroundColor White
    Write-Host "5. Once validated, update CloudFront to use the certificate" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ Deployment process completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update your domain nameservers to point to Route 53" -ForegroundColor White
Write-Host "2. Wait 5-60 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Test your domain: https://robertconsulting.net" -ForegroundColor White
Write-Host "4. Test WWW subdomain: https://www.robertconsulting.net" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To get nameservers:" -ForegroundColor Cyan
Write-Host "terraform output name_servers" -ForegroundColor White

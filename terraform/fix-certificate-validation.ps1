# Fix SSL Certificate Validation for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔧 Fixing SSL Certificate Validation for robertconsulting.net" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Checking current certificate status..." -ForegroundColor Yellow

# Get the certificate ARN from the error message
$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

Write-Host "📋 Certificate ARN: $CERT_ARN" -ForegroundColor Cyan

# Check certificate status
Write-Host "🔍 Checking certificate validation status..." -ForegroundColor Yellow
try {
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
} catch {
    Write-Host "⚠️  Could not retrieve certificate details. Continuing with fix..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Fixing certificate validation..." -ForegroundColor Green

# Option 1: Destroy the problematic certificate validation resource
Write-Host "1. Destroying the certificate validation resource..." -ForegroundColor Yellow
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve

# Option 2: Import the existing certificate
Write-Host "2. Importing the existing certificate..." -ForegroundColor Yellow
terraform import aws_acm_certificate.wildcard $CERT_ARN

# Option 3: Recreate the validation
Write-Host "3. Recreating certificate validation..." -ForegroundColor Yellow
terraform apply -target=aws_acm_certificate_validation.wildcard

Write-Host ""
Write-Host "✅ Certificate validation fix completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Check that DNS validation records are properly set in Route 53" -ForegroundColor White
Write-Host "2. Wait 2-3 minutes for DNS propagation" -ForegroundColor White
Write-Host "3. Run 'terraform apply' to complete the deployment" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To check certificate status:" -ForegroundColor Cyan
Write-Host "aws acm describe-certificate --certificate-arn '$CERT_ARN' --region us-east-1" -ForegroundColor White
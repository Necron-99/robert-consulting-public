# Fix Terraform State for robertconsulting.net
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔧 Fixing Terraform State for robertconsulting.net" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "infrastructure.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Checking current Terraform state..." -ForegroundColor Yellow
terraform state list

Write-Host ""
Write-Host "🔧 Step 1: Destroy problematic certificate validation..." -ForegroundColor Yellow
# Destroy the certificate validation that's causing issues
try {
    terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve
} catch {
    Write-Host "⚠️  Certificate validation destroy failed or already destroyed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Step 2: Import existing certificate..." -ForegroundColor Yellow
# Import the existing certificate
$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"
terraform import aws_acm_certificate.wildcard $CERT_ARN

Write-Host ""
Write-Host "🔧 Step 3: Check certificate status..." -ForegroundColor Yellow
aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus,Domain:DomainName}' --output table

Write-Host ""
Write-Host "🔧 Step 4: Import Route 53 hosted zone if it exists..." -ForegroundColor Yellow
# Check if hosted zone exists
try {
    $HOSTED_ZONE_ID = aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | ForEach-Object { $_ -replace '/hostedzone/', '' }
    if ($HOSTED_ZONE_ID) {
        Write-Host "✅ Found existing hosted zone: $HOSTED_ZONE_ID" -ForegroundColor Green
        terraform import aws_route53_zone.main $HOSTED_ZONE_ID
    } else {
        Write-Host "⚠️  No existing hosted zone found, will create new one" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check hosted zone" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Step 5: Import existing DNS validation records..." -ForegroundColor Yellow
# Import validation records if they exist
try {
    terraform import 'aws_route53_record.cert_validation["robertconsulting.net"]' "${HOSTED_ZONE_ID}_robertconsulting.net_CNAME"
} catch {
    Write-Host "⚠️  Could not import robertconsulting.net validation record" -ForegroundColor Yellow
}

try {
    terraform import 'aws_route53_record.cert_validation["*.robertconsulting.net"]' "${HOSTED_ZONE_ID}_*.robertconsulting.net_CNAME"
} catch {
    Write-Host "⚠️  Could not import *.robertconsulting.net validation record" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Step 6: Plan the deployment..." -ForegroundColor Yellow
terraform plan

Write-Host ""
Write-Host "🔧 Step 7: Apply the changes..." -ForegroundColor Yellow
terraform apply

Write-Host ""
Write-Host "✅ Terraform state fix completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Check that all resources are properly imported" -ForegroundColor White
Write-Host "2. Run 'terraform plan' to see if there are any remaining issues" -ForegroundColor White
Write-Host "3. Run 'terraform apply' to complete the deployment" -ForegroundColor White
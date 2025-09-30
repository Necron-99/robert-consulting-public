# Fix DNS Validation for SSL Certificate
# PowerShell script for Windows environments

param(
    [switch]$Force
)

Write-Host "🔧 Fixing DNS Validation for SSL Certificate" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

$CERT_ARN = "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f"

Write-Host "🔍 Step 1: Check certificate validation records..." -ForegroundColor Yellow
aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Status:ValidationStatus,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

Write-Host ""
Write-Host "🔍 Step 2: Check Route 53 hosted zone..." -ForegroundColor Yellow
$HOSTED_ZONE_ID = aws route53 list-hosted-zones --query 'HostedZones[?Name==`robertconsulting.net.`].Id' --output text | ForEach-Object { $_ -replace '/hostedzone/', '' }
Write-Host "Hosted Zone ID: $HOSTED_ZONE_ID" -ForegroundColor Cyan

if ($HOSTED_ZONE_ID) {
    Write-Host "🔍 Step 3: Check DNS records in Route 53..." -ForegroundColor Yellow
    aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query 'ResourceRecordSets[?Type==`CNAME`].{Name:Name,Type:Type,Value:ResourceRecords[0].Value}' --output table
}

Write-Host ""
Write-Host "🔧 Step 4: Destroy the certificate validation resource..." -ForegroundColor Yellow
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve

Write-Host ""
Write-Host "🔧 Step 5: Check if certificate is already validated..." -ForegroundColor Yellow
$CERT_STATUS = aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text
Write-Host "Certificate Status: $CERT_STATUS" -ForegroundColor Cyan

if ($CERT_STATUS -eq "ISSUED") {
    Write-Host "✅ Certificate is already validated! Skipping validation step." -ForegroundColor Green
    Write-Host ""
    Write-Host "🔧 Step 6: Comment out certificate validation in Terraform..." -ForegroundColor Yellow
    Write-Host "Edit domain-namecheap.tf and comment out the aws_acm_certificate_validation resource" -ForegroundColor White
    Write-Host "Then run: terraform apply" -ForegroundColor White
} else {
    Write-Host "⚠️  Certificate is still pending validation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 Step 6: Manual DNS validation approach..." -ForegroundColor Yellow
    Write-Host "1. Get the validation records:" -ForegroundColor White
    aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table
    
    Write-Host ""
    Write-Host "2. Manually add these CNAME records to your DNS provider" -ForegroundColor White
    Write-Host "3. Wait 5-10 minutes for DNS propagation" -ForegroundColor White
    Write-Host "4. Run: terraform apply -target=aws_acm_certificate_validation.wildcard" -ForegroundColor White
}

Write-Host ""
Write-Host "📋 Alternative: Skip certificate validation entirely" -ForegroundColor Cyan
Write-Host "If the certificate is already working, you can skip validation by:" -ForegroundColor White
Write-Host "1. Commenting out the aws_acm_certificate_validation resource" -ForegroundColor White
Write-Host "2. Updating the CloudFront distribution to use the certificate directly" -ForegroundColor White
Write-Host "3. Running terraform apply" -ForegroundColor White

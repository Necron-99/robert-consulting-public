# Diagnose CloudFront and S3 Configuration
# This script helps diagnose CloudFront and S3 issues

Write-Host "🔍 Diagnosing CloudFront and S3 Configuration" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

# Check if we're in the terraform directory
if (-not (Test-Path "domain-namecheap.tf")) {
    Write-Host "❌ Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Step 1: Checking S3 Bucket Configuration..." -ForegroundColor Yellow

# Get S3 bucket name
try {
    $bucketName = terraform output -raw website_bucket_name
    Write-Host "📋 S3 Bucket: $bucketName" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error getting S3 bucket name" -ForegroundColor Red
    exit 1
}

# Check if bucket exists
try {
    $null = aws s3 ls "s3://$bucketName" 2>$null
    Write-Host "✅ S3 bucket exists" -ForegroundColor Green
} catch {
    Write-Host "❌ S3 bucket does not exist or is not accessible" -ForegroundColor Red
    exit 1
}

# Check bucket contents
Write-Host "📋 S3 Bucket Contents:" -ForegroundColor Cyan
aws s3 ls "s3://$bucketName" --recursive

# Check if index.html exists
try {
    $null = aws s3 ls "s3://$bucketName/index.html" 2>$null
    Write-Host "✅ index.html exists in S3" -ForegroundColor Green
} catch {
    Write-Host "❌ index.html not found in S3 bucket" -ForegroundColor Red
    Write-Host "This is likely the cause of the 404 error" -ForegroundColor Yellow
}

# Check if error.html exists
try {
    $null = aws s3 ls "s3://$bucketName/error.html" 2>$null
    Write-Host "✅ error.html exists in S3" -ForegroundColor Green
} catch {
    Write-Host "❌ error.html not found in S3 bucket" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔍 Step 2: Checking CloudFront Distribution..." -ForegroundColor Yellow

# Get CloudFront distribution details
try {
    $distributionId = terraform output -raw cloudfront_distribution_id
    Write-Host "📋 Distribution ID: $distributionId" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error getting CloudFront distribution ID" -ForegroundColor Red
    exit 1
}

# Get CloudFront configuration
Write-Host "📋 CloudFront Configuration:" -ForegroundColor Cyan
aws cloudfront get-distribution --id $distributionId --query 'Distribution.DistributionConfig.{Origins:Origins,DefaultCacheBehavior:DefaultCacheBehavior,DefaultRootObject:DefaultRootObject}' --output table

Write-Host ""
Write-Host "🔍 Step 3: Checking Website Files..." -ForegroundColor Yellow

# Check if website files exist locally
if (Test-Path "../website") {
    Write-Host "📋 Local website files:" -ForegroundColor Cyan
    Get-ChildItem "../website" | Format-Table Name, Length, LastWriteTime
    
    Write-Host ""
    Write-Host "📋 Checking for required files:" -ForegroundColor Cyan
    if (Test-Path "../website/index.html") {
        Write-Host "✅ index.html exists locally" -ForegroundColor Green
    } else {
        Write-Host "❌ index.html not found locally" -ForegroundColor Red
    }
    
    if (Test-Path "../website/error.html") {
        Write-Host "✅ error.html exists locally" -ForegroundColor Green
    } else {
        Write-Host "❌ error.html not found locally" -ForegroundColor Red
    }
} else {
    Write-Host "❌ ../website directory not found" -ForegroundColor Red
    Write-Host "Website files may not be deployed to S3" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Step 4: Diagnosis Summary..." -ForegroundColor Yellow

Write-Host "📋 Issues Found:" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

# Check if files are missing
try {
    $null = aws s3 ls "s3://$bucketName/index.html" 2>$null
} catch {
    Write-Host "❌ index.html missing from S3 bucket" -ForegroundColor Red
    Write-Host "   Solution: Upload website files to S3" -ForegroundColor Yellow
}

try {
    $null = aws s3 ls "s3://$bucketName/error.html" 2>$null
} catch {
    Write-Host "❌ error.html missing from S3 bucket" -ForegroundColor Red
    Write-Host "   Solution: Upload website files to S3" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Solutions:" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green

Write-Host "1. Upload Website Files to S3:" -ForegroundColor White
Write-Host "   aws s3 sync ../website/ s3://$bucketName --delete" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Create Missing Files:" -ForegroundColor White
Write-Host "   # Create index.html if missing" -ForegroundColor Gray
Write-Host "   echo '<html><body><h1>Robert Consulting</h1></body></html>' > ../website/index.html" -ForegroundColor Gray
Write-Host "   # Create error.html if missing" -ForegroundColor Gray
Write-Host "   echo '<html><body><h1>404 - Page Not Found</h1></body></html>' > ../website/error.html" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Deploy Website Files:" -ForegroundColor White
Write-Host "   # From project root directory" -ForegroundColor Gray
Write-Host "   cd .." -ForegroundColor Gray
Write-Host "   aws s3 sync website/ s3://$bucketName --delete" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Invalidate CloudFront Cache:" -ForegroundColor White
Write-Host "   aws cloudfront create-invalidation --distribution-id $distributionId --paths '/*'" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Test After Deployment:" -ForegroundColor White
Write-Host "   curl -I https://$(terraform output -raw cloudfront_distribution_domain_name)" -ForegroundColor Gray
Write-Host ""

Write-Host "🔍 To check S3 bucket policy:" -ForegroundColor Cyan
Write-Host "aws s3api get-bucket-policy --bucket $bucketName" -ForegroundColor Gray
Write-Host ""
Write-Host "🔍 To check S3 website configuration:" -ForegroundColor Cyan
Write-Host "aws s3api get-bucket-website --bucket $bucketName" -ForegroundColor Gray


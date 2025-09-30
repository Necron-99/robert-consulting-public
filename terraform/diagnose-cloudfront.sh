#!/bin/bash

# Diagnose CloudFront and S3 Configuration
# This script helps diagnose CloudFront and S3 issues

set -e

echo "🔍 Diagnosing CloudFront and S3 Configuration"
echo "==========================================="

# Check if we're in the terraform directory
if [ ! -f "domain-namecheap.tf" ]; then
    echo "❌ Error: Please run this script from the terraform directory"
    exit 1
fi

echo "🔍 Step 1: Checking S3 Bucket Configuration..."

# Get S3 bucket name
BUCKET_NAME=$(terraform output -raw website_bucket_name)
echo "📋 S3 Bucket: $BUCKET_NAME"

# Check if bucket exists
if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
    echo "✅ S3 bucket exists"
else
    echo "❌ S3 bucket does not exist or is not accessible"
    exit 1
fi

# Check bucket contents
echo "📋 S3 Bucket Contents:"
aws s3 ls "s3://$BUCKET_NAME" --recursive

# Check if index.html exists
if aws s3 ls "s3://$BUCKET_NAME/index.html" > /dev/null 2>&1; then
    echo "✅ index.html exists in S3"
else
    echo "❌ index.html not found in S3 bucket"
    echo "This is likely the cause of the 404 error"
fi

# Check if error.html exists
if aws s3 ls "s3://$BUCKET_NAME/error.html" > /dev/null 2>&1; then
    echo "✅ error.html exists in S3"
else
    echo "❌ error.html not found in S3 bucket"
fi

echo ""
echo "🔍 Step 2: Checking CloudFront Distribution..."

# Get CloudFront distribution details
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
echo "📋 Distribution ID: $DISTRIBUTION_ID"

# Get CloudFront configuration
echo "📋 CloudFront Configuration:"
aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query 'Distribution.DistributionConfig.{Origins:Origins,DefaultCacheBehavior:DefaultCacheBehavior,DefaultRootObject:DefaultRootObject}' --output table

echo ""
echo "🔍 Step 3: Checking Website Files..."

# Check if website files exist locally
if [ -d "../website" ]; then
    echo "📋 Local website files:"
    ls -la ../website/
    
    echo ""
    echo "📋 Checking for required files:"
    if [ -f "../website/index.html" ]; then
        echo "✅ index.html exists locally"
    else
        echo "❌ index.html not found locally"
    fi
    
    if [ -f "../website/error.html" ]; then
        echo "✅ error.html exists locally"
    else
        echo "❌ error.html not found locally"
    fi
else
    echo "❌ ../website directory not found"
    echo "Website files may not be deployed to S3"
fi

echo ""
echo "🔍 Step 4: Diagnosis Summary..."

echo "📋 Issues Found:"
echo "================"

# Check if files are missing
if ! aws s3 ls "s3://$BUCKET_NAME/index.html" > /dev/null 2>&1; then
    echo "❌ index.html missing from S3 bucket"
    echo "   Solution: Upload website files to S3"
fi

if ! aws s3 ls "s3://$BUCKET_NAME/error.html" > /dev/null 2>&1; then
    echo "❌ error.html missing from S3 bucket"
    echo "   Solution: Upload website files to S3"
fi

echo ""
echo "🔧 Solutions:"
echo "============="

echo "1. Upload Website Files to S3:"
echo "   aws s3 sync ../website/ s3://$BUCKET_NAME --delete"
echo ""

echo "2. Create Missing Files:"
echo "   # Create index.html if missing"
echo "   echo '<html><body><h1>Robert Consulting</h1></body></html>' > ../website/index.html"
echo "   # Create error.html if missing"
echo "   echo '<html><body><h1>404 - Page Not Found</h1></body></html>' > ../website/error.html"
echo ""

echo "3. Deploy Website Files:"
echo "   # From project root directory"
echo "   cd .."
echo "   aws s3 sync website/ s3://$BUCKET_NAME --delete"
echo ""

echo "4. Invalidate CloudFront Cache:"
echo "   aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
echo ""

echo "5. Test After Deployment:"
echo "   curl -I https://$(terraform output -raw cloudfront_distribution_domain_name)"
echo ""

echo "🔍 To check S3 bucket policy:"
echo "aws s3api get-bucket-policy --bucket $BUCKET_NAME"
echo ""
echo "🔍 To check S3 website configuration:"
echo "aws s3api get-bucket-website --bucket $BUCKET_NAME"



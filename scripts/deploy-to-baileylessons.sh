#!/bin/bash
# Simple script to deploy local files to Bailey Lessons S3 bucket

set -e

# Configuration
S3_BUCKET_NAME="baileylessons-production-static"
CLOUDFRONT_DISTRIBUTION_ID="E23X7BS3VXFFFZ"
AWS_REGION="us-east-1"

# Get source directory (default to current directory)
SOURCE_DIR=${1:-.}

echo "🎓 Deploying to Bailey Lessons website..."
echo "📋 Configuration:"
echo "   Source: $SOURCE_DIR"
echo "   S3 Bucket: $S3_BUCKET_NAME"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory '$SOURCE_DIR' not found"
    echo "   Usage: $0 [source-directory]"
    echo "   Example: $0 ./my-website-files"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured"
    exit 1
fi

# Assume role into Bailey Lessons client account
echo "🔄 Assuming role into Bailey Lessons client account..."
ROLE_ARN="arn:aws:iam::737915157697:role/OrganizationAccountAccessRole"
SESSION_NAME="baileylessons-deployment-$(date +%s)"

# Assume the role and get temporary credentials
CREDENTIALS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to assume role into Bailey Lessons account"
    echo "   Please check:"
    echo "   1. You have permission to assume the OrganizationAccountAccessRole"
    echo "   2. The role exists in account 737915157697"
    echo "   3. Your AWS credentials are properly configured"
    exit 1
fi

# Extract credentials
ACCESS_KEY=$(echo $CREDENTIALS | cut -d' ' -f1)
SECRET_KEY=$(echo $CREDENTIALS | cut -d' ' -f2)
SESSION_TOKEN=$(echo $CREDENTIALS | cut -d' ' -f3)

# Set environment variables for the assumed role
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"

# Verify we're now in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
EXPECTED_ACCOUNT="737915157697"

if [ "$CURRENT_ACCOUNT" != "$EXPECTED_ACCOUNT" ]; then
    echo "❌ Error: Failed to assume role into Bailey Lessons account"
    echo "   Current account: $CURRENT_ACCOUNT"
    echo "   Expected account: $EXPECTED_ACCOUNT"
    exit 1
fi

echo "✅ Successfully assumed role into Bailey Lessons account ($CURRENT_ACCOUNT)"

# Verify S3 bucket access
echo "🔍 Verifying S3 bucket access..."
if ! aws s3 ls "s3://$S3_BUCKET_NAME" > /dev/null 2>&1; then
    echo "❌ Error: Cannot access S3 bucket '$S3_BUCKET_NAME'"
    exit 1
fi

# Show what will be deployed
echo "📋 Files to be deployed:"
ls -la "$SOURCE_DIR"

# Ask for confirmation
echo ""
read -p "Deploy these files to baileylessons.com? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Deploy to S3
echo "🚀 Deploying to S3..."

# Sync with appropriate cache headers
aws s3 sync "$SOURCE_DIR/" "s3://$S3_BUCKET_NAME/" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "*.css" \
    --exclude "*.js"

# Sync HTML/CSS/JS with shorter cache
aws s3 sync "$SOURCE_DIR/" "s3://$S3_BUCKET_NAME/" \
    --cache-control "public, max-age=3600" \
    --include "*.html" \
    --include "*.css" \
    --include "*.js"

echo "✅ Files deployed to S3"

# Create CloudFront invalidation
echo "🔄 Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "✅ CloudFront invalidation created: $INVALIDATION_ID"

echo ""
echo "🎉 Deployment complete!"
echo "🌐 Changes will be live at https://baileylessons.com in 5-15 minutes"

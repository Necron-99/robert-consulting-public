#!/bin/bash
# Update Bailey Lessons website content
# Deploys from GitHub repository to existing S3 bucket and invalidates CloudFront

set -e

echo "🎓 Updating Bailey Lessons website content..."

# Configuration
GITHUB_REPO="Necron-99/baileylessons.com"
S3_BUCKET_NAME="baileylessons-production-static"  # Existing bucket from console
CLOUDFRONT_DISTRIBUTION_ID="E23X7BS3VXFFFZ"  # Existing distribution from console
AWS_REGION="us-east-1"
TEMP_DIR="/tmp/baileylessons-deploy"

echo "📋 Configuration:"
echo "   Repository: $GITHUB_REPO"
echo "   S3 Bucket: $S3_BUCKET_NAME"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Region: $AWS_REGION"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured or not authenticated"
    echo "   Please run 'aws configure' or set up AWS credentials"
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

# Verify S3 bucket exists and is accessible
echo "🔍 Verifying S3 bucket access..."
if ! aws s3 ls "s3://$S3_BUCKET_NAME" > /dev/null 2>&1; then
    echo "❌ Error: Cannot access S3 bucket '$S3_BUCKET_NAME'"
    echo "   Please check:"
    echo "   1. Bucket name is correct"
    echo "   2. AWS credentials have S3 access"
    echo "   3. You're using the correct AWS account"
    exit 1
fi

# Verify CloudFront distribution exists
echo "🔍 Verifying CloudFront distribution..."
if ! aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" > /dev/null 2>&1; then
    echo "❌ Error: Cannot access CloudFront distribution '$CLOUDFRONT_DISTRIBUTION_ID'"
    echo "   Please check the distribution ID is correct"
    exit 1
fi

# Clean up any existing temp directory
if [ -d "$TEMP_DIR" ]; then
    echo "🧹 Cleaning up previous deployment..."
    rm -rf "$TEMP_DIR"
fi

# Clone the repository using existing GitHub credentials
echo "📥 Cloning repository: $GITHUB_REPO"

# Try different authentication methods
if [ -n "$GITHUB_TOKEN" ]; then
    echo "🔑 Using GITHUB_TOKEN environment variable"
    git clone "https://$GITHUB_TOKEN@github.com/$GITHUB_REPO.git" "$TEMP_DIR"
elif [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_PASSWORD" ]; then
    echo "🔑 Using GITHUB_USERNAME and GITHUB_PASSWORD environment variables"
    git clone "https://$GITHUB_USERNAME:$GITHUB_PASSWORD@github.com/$GITHUB_REPO.git" "$TEMP_DIR"
elif git config --global user.name > /dev/null 2>&1; then
    echo "🔑 Using configured Git credentials"
    git clone "https://github.com/$GITHUB_REPO.git" "$TEMP_DIR"
else
    echo "❌ Error: No GitHub authentication found"
    echo "   Please set one of the following:"
    echo "   1. GITHUB_TOKEN environment variable"
    echo "   2. GITHUB_USERNAME and GITHUB_PASSWORD environment variables"
    echo "   3. Configure Git credentials with 'git config --global user.name' and 'git config --global user.email'"
    echo ""
    echo "   For GitHub token:"
    echo "   export GITHUB_TOKEN=your_github_token"
    echo ""
    echo "   For Git config:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to clone repository"
    echo "   Please check your GitHub credentials and repository access"
    exit 1
fi

cd "$TEMP_DIR"

# Check if repository has content and determine content directory
CONTENT_DIR=""

# Check for common content directories and files
if [ -d "content/website" ]; then
    CONTENT_DIR="content/website"
    echo "📁 Found content in 'content/website/' directory"
elif [ -d "content" ]; then
    CONTENT_DIR="content"
    echo "📁 Found content in 'content/' directory"
elif [ -d "dist" ]; then
    CONTENT_DIR="dist"
    echo "📁 Found content in 'dist/' directory"
elif [ -d "public" ]; then
    CONTENT_DIR="public"
    echo "📁 Found content in 'public/' directory"
elif [ -d "build" ]; then
    CONTENT_DIR="build"
    echo "📁 Found content in 'build/' directory"
elif [ -d "src" ]; then
    CONTENT_DIR="src"
    echo "📁 Found content in 'src/' directory"
elif [ -f "index.html" ]; then
    CONTENT_DIR="."
    echo "📁 Found content in root directory"
else
    echo "❌ Error: No website content found in repository"
    echo "   Expected directories: content/website/, content/, dist/, public/, build/, src/"
    echo "   Expected files: index.html"
    echo "   Current directory contents:"
    ls -la
    echo ""
    echo "   Available directories:"
    find . -maxdepth 2 -type d -name "*" | grep -v "^\.$" | sort
    exit 1
fi

# Verify the content directory has website files
if [ ! -f "$CONTENT_DIR/index.html" ] && [ ! -f "$CONTENT_DIR/index.htm" ] && [ ! -f "$CONTENT_DIR/index.php" ]; then
    echo "⚠️  Warning: No index.html found in $CONTENT_DIR/"
    echo "   Contents of $CONTENT_DIR/:"
    ls -la "$CONTENT_DIR/"
    echo ""
    echo "   Proceeding anyway - some sites may not have index.html"
fi

echo "📁 Using content directory: $CONTENT_DIR"

# Show what will be deployed
echo "📋 Content to be deployed:"
ls -la "$CONTENT_DIR"

# Ask for confirmation
echo ""
read -p "Deploy this content to baileylessons.com? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Deploy to S3
echo "🚀 Deploying content to S3..."
echo "   Source: $TEMP_DIR/$CONTENT_DIR"
echo "   Destination: s3://$S3_BUCKET_NAME"

# Sync content to S3 with appropriate cache headers
aws s3 sync "$CONTENT_DIR/" "s3://$S3_BUCKET_NAME/" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "*.css" \
    --exclude "*.js"

# Sync HTML/CSS/JS with shorter cache
aws s3 sync "$CONTENT_DIR/" "s3://$S3_BUCKET_NAME/" \
    --cache-control "public, max-age=3600" \
    --include "*.html" \
    --include "*.css" \
    --include "*.js"

echo "✅ Content deployed to S3 successfully"

# Create CloudFront invalidation
echo "🔄 Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "✅ CloudFront invalidation created: $INVALIDATION_ID"

# Clean up temp directory
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

# Get website URL
WEBSITE_URL="https://baileylessons.com"

echo ""
echo "🎉 Bailey Lessons website updated successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   Repository: $GITHUB_REPO"
echo "   S3 Bucket: $S3_BUCKET_NAME"
echo "   CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Invalidation ID: $INVALIDATION_ID"
echo "   Website URL: $WEBSITE_URL"
echo ""
echo "🌐 Your changes will be live at $WEBSITE_URL in 5-15 minutes"
echo "   CloudFront cache invalidation is in progress"
echo ""
echo "📊 To monitor the invalidation:"
echo "   aws cloudfront get-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --id $INVALIDATION_ID"

#!/bin/bash
# Deploy Bailey Lessons Admin Site

set -e

echo "🎓 Deploying Bailey Lessons Admin Site..."

# Configuration
CLIENT_NAME="baileylessons"
GITHUB_REPO="Necron-99/baileylessons.com"
S3_BUCKET_NAME="baileylessons-production-static"  # Existing bucket
CLOUDFRONT_DISTRIBUTION_ID="E23X7BS3VXFFFZ"  # Existing distribution
AWS_REGION="us-east-1"

echo "📋 Configuration:"
echo "   Client: $CLIENT_NAME"
echo "   Repository: $GITHUB_REPO"
echo "   S3 Bucket: $S3_BUCKET_NAME"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Region: $AWS_REGION"

# Check if we're in the right directory
if [ ! -d "admin/baileylessons" ]; then
    echo "❌ Error: admin/baileylessons directory not found"
    echo "   Please run this script from the robert-consulting.net root directory"
    exit 1
fi

# Deploy admin site infrastructure
echo "🏗️  Deploying admin site infrastructure..."
cd terraform/clients/baileylessons

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the deployment
echo "📋 Planning admin site deployment..."
terraform plan -target=aws_s3_bucket.admin -target=aws_cloudfront_distribution.admin

# Ask for confirmation
read -p "Deploy Bailey Lessons admin site? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply the infrastructure
echo "🚀 Deploying infrastructure..."
terraform apply -target=aws_s3_bucket.admin -target=aws_cloudfront_distribution.admin -auto-approve

# Get the admin bucket name
ADMIN_BUCKET=$(terraform output -raw admin_bucket)
echo "✅ Admin bucket: $ADMIN_BUCKET"

# Upload admin files
echo "📤 Uploading admin site files..."
cd ../../..
aws s3 sync ./admin/baileylessons/ s3://$ADMIN_BUCKET --delete

echo "✅ Admin site files uploaded to s3://$ADMIN_BUCKET"

# Create CloudFront invalidation
echo "🔄 Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*" --query 'Invalidation.Id' --output text)
echo "✅ Invalidation created: $INVALIDATION_ID"

# Get admin URL
ADMIN_URL=$(terraform output -raw admin_url)
echo ""
echo "🎉 Bailey Lessons Admin Site Deployed Successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   Admin URL: $ADMIN_URL"
echo "   S3 Bucket: $ADMIN_BUCKET"
echo "   CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Invalidation ID: $INVALIDATION_ID"
echo ""
echo "🔐 Admin Credentials:"
echo "   Username: bailey_admin"
echo "   Password: BaileySecure2025!"
echo ""
echo "🌐 Access the admin site at: $ADMIN_URL"
echo "   Changes will be live in 5-15 minutes"
echo ""
echo "📊 Next Steps:"
echo "   1. Test admin access at $ADMIN_URL"
echo "   2. Configure content deployment from $GITHUB_REPO"
echo "   3. Set up monitoring and alerts"
echo "   4. Update DNS if needed (admin.baileylessons.com)"

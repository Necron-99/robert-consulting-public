#!/bin/bash

# Deploy Testing Infrastructure
# This script creates the testing S3 bucket and CloudFront distribution with proper permissions

set -e

echo "🚀 Deploying testing infrastructure..."

# Navigate to terraform directory
cd "$(dirname "$0")"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the testing infrastructure
echo "📋 Planning testing infrastructure..."
terraform plan -target=aws_s3_bucket.testing_site \
               -target=aws_s3_bucket_public_access_block.testing_site \
               -target=aws_s3_bucket_website_configuration.testing_site \
               -target=aws_s3_bucket_policy.testing_site \
               -target=aws_cloudfront_distribution.testing_site

# Apply the testing infrastructure
echo "🏗️ Creating testing infrastructure..."
terraform apply -target=aws_s3_bucket.testing_site \
                -target=aws_s3_bucket_public_access_block.testing_site \
                -target=aws_s3_bucket_website_configuration.testing_site \
                -target=aws_s3_bucket_policy.testing_site \
                -target=aws_cloudfront_distribution.testing_site \
                -auto-approve

# Get outputs
echo "📊 Testing infrastructure outputs:"
echo "  Bucket Name: $(terraform output -raw testing_bucket_name)"
echo "  Website URL: $(terraform output -raw testing_bucket_website_url)"
echo "  CloudFront URL: $(terraform output -raw testing_cloudfront_url)"

echo "✅ Testing infrastructure deployed successfully!"
echo "🔧 The testing bucket is now properly configured with public access"
echo "🚀 GitHub Actions can now deploy to this bucket without permission issues"

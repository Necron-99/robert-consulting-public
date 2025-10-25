#!/bin/bash
# Linux Import Script for Orphaned Resources
# Run this on your Linux box to import all orphaned resources

set -e  # Exit on any error

echo "🔧 === LINUX IMPORT SCRIPT ==="
echo "Importing orphaned AWS resources into Terraform state"
echo ""

# Check if we're in the right directory
if [ ! -f "terraform.tf" ] && [ ! -d "terraform" ]; then
    echo "❌ Error: Not in terraform directory. Please cd to terraform/ first"
    exit 1
fi

# Navigate to terraform directory if needed
if [ -d "terraform" ]; then
    cd terraform
fi

echo "📋 Step 1: Initializing Terraform..."
terraform init

echo "📋 Step 2: Checking current state..."
terraform state list

echo "📋 Step 3: Importing Plex S3 buckets..."
terraform import aws_s3_bucket.plex_recommendations_data plex-recommendations-data-1e15cfbc
terraform import aws_s3_bucket.plex_domain plex.robertconsulting.net

echo "📋 Step 4: Importing Plex CloudFront distribution..."
terraform import aws_cloudfront_distribution.plex_distribution E3T1Z34I8CU20F

echo "📋 Step 5: Importing Plex Lambda functions..."
terraform import aws_lambda_function.plex_analyzer plex-analyzer
terraform import aws_lambda_function.robert_consulting_plex_analyzer robert-consulting-plex-analyzer
terraform import aws_lambda_function.terraform_stats_refresher robert-consulting-terraform-stats-refresher

echo "📋 Step 6: Importing cache and test buckets..."
terraform import aws_s3_bucket.cache robert-consulting-cache
terraform import aws_s3_bucket.terraform_test robert-consulting-terraform-test-1761410906

echo "📋 Step 7: Verifying all imports..."
terraform state list

echo "📋 Step 8: Running plan to check for issues..."
terraform plan

echo "✅ === IMPORT COMPLETE ==="
echo "All orphaned resources have been imported into Terraform state"
echo "Run 'terraform plan' to see any configuration mismatches"

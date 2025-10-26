#!/bin/bash

echo "🔧 === IMPORTING EXISTING CLOUDFRONT DISTRIBUTIONS ==="
echo ""
echo "You're absolutely right! We should import the existing CloudFront distributions"
echo "instead of trying to create new ones."
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 STEP 1: Import Existing Plex CloudFront Distribution"
echo "======================================================"
echo "Importing the existing Plex CloudFront distribution..."
echo "Distribution ID: E3T1Z3418CU20F"
echo "Domain: plex.robertconsulting.net"
terraform import aws_cloudfront_distribution.plex_distribution E3T1Z3418CU20F

echo ""
echo "📋 STEP 2: Import Existing S3 Buckets"
echo "====================================="
echo "Importing existing S3 buckets that are already in use..."
terraform import aws_s3_bucket.plex_domain plex.robertconsulting.net
terraform import aws_s3_bucket.plex_recommendations_data plex-recommendations-data-1e15cfbc

echo ""
echo "📋 STEP 3: Import Existing Lambda Functions"
echo "=========================================="
echo "Importing existing Lambda functions..."
terraform import aws_lambda_function.plex_analyzer plex-analyzer
terraform import aws_lambda_function.robert_consulting_plex_analyzer robert-consulting-plex-analyzer

echo ""
echo "📋 STEP 4: Import CloudFront Origin Access Identity"
echo "=================================================="
echo "Getting OAI ID from the existing distribution..."
echo "Note: We need to get the OAI ID from the CloudFront distribution"

echo ""
echo "🎯 WHY THIS APPROACH IS BETTER:"
echo "==============================="
echo "✅ Import existing resources instead of creating new ones"
echo "✅ Avoid conflicts with existing infrastructure"
echo "✅ Preserve existing configurations and settings"
echo "✅ Much faster and safer than recreating everything"
echo ""
echo "🚀 This is the correct approach - import first, then manage!"

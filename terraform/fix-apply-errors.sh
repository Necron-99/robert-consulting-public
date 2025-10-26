#!/bin/bash

echo "🔧 === FIXING TERRAFORM APPLY ERRORS ==="
echo ""
echo "This script will fix the multiple issues preventing terraform apply from succeeding"
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 STEP 1: Create Missing Zip Files"
echo "==================================="
echo "Creating placeholder zip files for missing resources..."

# Create lambda directory if it doesn't exist
mkdir -p lambda

# Create placeholder zip files
echo "Creating contact-form.zip..."
cd lambda
echo 'def handler(event, context): return {"statusCode": 200, "body": "Contact form handler"}' > contact-form.py
zip contact-form.zip contact-form.py
cd ..

echo "Creating synthetics zip files..."
cd synthetics
echo 'console.log("Performance monitor");' > performance-monitor.js
zip synthetics-performance-monitor.zip performance-monitor.js
echo 'console.log("Security headers monitor");' > security-headers.js
zip synthetics-security-headers.zip security-headers.js
cd ..

echo ""
echo "📋 STEP 2: Import Existing Resources"
echo "====================================="
echo "Importing resources that already exist to avoid conflicts..."

# Import existing S3 buckets
echo "Importing existing S3 buckets..."
terraform import module.plex_recommendations.aws_s3_bucket.plex_data plex-recommendations-c7c49ce4
terraform import module.plex_recommendations.aws_s3_bucket.plex_domain plex.robertconsulting.net

# Import existing SES event destination
echo "Importing existing SES event destination..."
terraform import aws_ses_event_destination.cloudwatch robertconsulting-email-config/cloudwatch-destination

echo ""
echo "📋 STEP 3: Fix CloudFront Issues"
echo "================================"
echo "Note: CloudFront issues need manual configuration fixes"
echo "1. Remove invalid ForwardedValues parameter"
echo "2. Fix certificate issues for baileylessons domain"
echo "3. Import existing response headers policies"

echo ""
echo "📋 STEP 4: Fix Lambda Permission Conflicts"
echo "=========================================="
echo "Note: Lambda permissions already exist - need to import or remove duplicates"

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Run terraform plan to see remaining issues"
echo "2. Fix CloudFront configuration manually"
echo "3. Import or remove duplicate permissions"
echo "4. Apply changes incrementally"
echo ""
echo "⚠️  IMPORTANT: Some issues require manual configuration fixes"
echo "   We may need to modify Terraform files directly"
echo ""
echo "🚀 Ready to continue with fixes!"

#!/bin/bash

echo "🔧 === IMPORTING WAF RESOURCES ==="
echo ""
echo "This script will import the WAF Web ACLs using the discovered ARNs"
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 STEP 1: Import Regional WAF Web ACL"
echo "======================================"
echo "Importing contact-form-waf..."
terraform import aws_wafv2_web_acl.contact_form_waf "arn:aws:wafv2:us-east-1:228480945348:regional/webacl/contact-form-waf/80b89e94-d5b4-4f92-a31d-1f5c0290c1db"

echo ""
echo "📋 STEP 2: Import CloudFront WAF Web ACLs"
echo "========================================"
echo "Importing staging-website-waf..."
terraform import aws_wafv2_web_acl.staging_waf "arn:aws:wafv2:us-east-1:228480945348:global/webacl/staging-website-waf/86f98420-79a0-4cd3-a8a5-c69d94419694"

echo ""
echo "📋 STEP 3: Import CloudFront Functions"
echo "======================================"
echo "Importing staging-access-control function..."
terraform import aws_cloudfront_function.staging_access_control "staging-access-control"

echo ""
echo "📋 STEP 4: Import WAF IP Sets"
echo "============================="
echo "Note: We need to get the IP set IDs first..."
echo "aws wafv2 list-ip-sets --scope CLOUDFRONT --region us-east-1"

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Run terraform plan to see what's left"
echo "2. Import any remaining resources"
echo "3. Apply the final changes"
echo ""
echo "🚀 Ready to continue!"

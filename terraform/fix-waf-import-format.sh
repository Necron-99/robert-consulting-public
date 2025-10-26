#!/bin/bash

echo "🔧 === FIXING WAF IMPORT FORMAT ==="
echo ""
echo "WAF imports need format: ID/NAME/SCOPE instead of full ARN"
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 STEP 1: Import Regional WAF Web ACL (Correct Format)"
echo "======================================================"
echo "Format: ID/NAME/SCOPE"
echo "For contact-form-waf: 80b89e94-d5b4-4f92-a31d-1f5c0290c1db/contact-form-waf/REGIONAL"
terraform import aws_wafv2_web_acl.contact_form_waf "80b89e94-d5b4-4f92-a31d-1f5c0290c1db/contact-form-waf/REGIONAL"

echo ""
echo "📋 STEP 2: Import CloudFront WAF Web ACL (Correct Format)"
echo "========================================================="
echo "Format: ID/NAME/SCOPE"
echo "For staging-website-waf: 86f98420-79a0-4cd3-a8a5-c69d94419694/staging-website-waf/CLOUDFRONT"
terraform import aws_wafv2_web_acl.staging_waf "86f98420-79a0-4cd3-a8a5-c69d94419694/staging-website-waf/CLOUDFRONT"

echo ""
echo "📋 STEP 3: Get WAF IP Set IDs"
echo "============================="
echo "Getting WAF IP set IDs for import..."
aws wafv2 list-ip-sets --scope CLOUDFRONT --region us-east-1 --query 'IPSets[].{Name:Name,Id:Id}' --output table

echo ""
echo "📋 STEP 4: Import WAF IP Sets (if needed)"
echo "=========================================="
echo "Note: We'll need the IP set IDs from the table above"
echo "Format: ID/NAME/SCOPE"

echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Run the corrected WAF imports above"
echo "2. Import any IP sets that are needed"
echo "3. Run terraform plan to see what's left"
echo "4. Apply the final changes"
echo ""
echo "🚀 Ready to continue with corrected format!"

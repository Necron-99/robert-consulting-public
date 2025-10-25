#!/bin/bash

# Bailey Lessons Import Plan
# This script provides the import commands for baileylessons resources

echo "🎯 === BAILEYLESSONS IMPORT PLAN ==="
echo ""
echo "🛡️ SAFE MIGRATION APPROACH:"
echo "• One resource at a time"
echo "• Validate after each step"
echo "• Test functionality"
echo "• Complete rollback capability"
echo ""

echo "📋 STEP 1: Import S3 Bucket (Least Critical)"
echo "terraform import module.baileylessons.aws_s3_bucket.admin baileylessons-admin-<random-hex>"
echo ""

echo "📋 STEP 2: Import S3 Configurations"
echo "terraform import module.baileylessons.aws_s3_bucket_public_access_block.admin baileylessons-admin-<random-hex>"
echo "terraform import module.baileylessons.aws_s3_bucket_versioning.admin baileylessons-admin-<random-hex>"
echo "terraform import module.baileylessons.aws_s3_bucket_server_side_encryption_configuration.admin baileylessons-admin-<random-hex>"
echo ""

echo "📋 STEP 3: Import Random ID"
echo "terraform import module.baileylessons.random_id.admin_suffix <random-hex>"
echo ""

echo "📋 STEP 4: Import CloudFront OAC"
echo "terraform import module.baileylessons.aws_cloudfront_origin_access_control.admin <oac-id>"
echo ""

echo "📋 STEP 5: Import S3 Bucket Policy"
echo "terraform import module.baileylessons.aws_s3_bucket_policy.admin baileylessons-admin-<random-hex>"
echo ""

echo "📋 STEP 6: Import CloudFront Function"
echo "terraform import module.baileylessons.aws_cloudfront_function.basic_auth <function-name>"
echo ""

echo "📋 STEP 7: Import CloudFront Distribution"
echo "terraform import module.baileylessons.aws_cloudfront_distribution.admin <distribution-id>"
echo ""

echo "📋 STEP 8: Import Route53 Record"
echo "terraform import module.baileylessons.aws_route53_record.admin <zone-id>_admin.baileylessons.com_A"
echo ""

echo "🛡️ SAFETY CHECKLIST:"
echo "• Run 'terraform plan' before each import"
echo "• Validate no unexpected changes"
echo "• Test functionality after each step"
echo "• Have rollback plan ready"
echo ""

echo "🚨 ROLLBACK PLAN:"
echo "cp terraform.tfstate.backup-20251025-112151 terraform.tfstate"
echo "terraform init"
echo "terraform plan  # Should show no changes"
echo ""

echo "✅ READY FOR MIGRATION!"
echo "Next step: Begin with Step 1 - Import S3 bucket"

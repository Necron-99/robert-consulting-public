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

echo "📋 STEP 1: Import S3 Buckets"
echo "terraform import aws_s3_bucket.production_static baileylessons-production-static"
echo "terraform import aws_s3_bucket.production_backups baileylessons-production-backups"
echo "terraform import aws_s3_bucket.production_uploads baileylessons-production-uploads"
echo "terraform import aws_s3_bucket.website baileylessons-website-586389c4"
echo ""

echo "📋 STEP 2: Import S3 Configurations"
echo "terraform import aws_s3_bucket_versioning.production_static baileylessons-production-static"
echo "terraform import aws_s3_bucket_server_side_encryption_configuration.production_static baileylessons-production-static"
echo "terraform import aws_s3_bucket_public_access_block.production_static baileylessons-production-static"
echo ""

echo "📋 STEP 3: Import CloudFront Resources"
echo "terraform import aws_cloudfront_distribution.main E23X7BS3VXFFFZ"
echo "terraform import aws_cloudfront_origin_access_identity.main <oai-id>"
echo ""

echo "📋 STEP 4: Import Route53 Zone"
echo "terraform import aws_route53_zone.main Z01009052GCOJI1M2TTF7"
echo ""

echo "📋 STEP 5: Import Lambda Functions"
echo "terraform import aws_lambda_function.production_api baileylessons-production-api"
echo "terraform import aws_lambda_function.production_admin baileylessons-production-admin"
echo "terraform import aws_lambda_function.production_auth baileylessons-production-auth"
echo ""

echo "📋 STEP 6: Import IAM Role"
echo "terraform import aws_iam_role.lambda_role <role-name>"
echo ""

echo "🛡️ SAFETY CHECKLIST:"
echo "• Run 'terraform plan' before each import"
echo "• Validate no unexpected changes"
echo "• Test functionality after each step"
echo "• Have rollback plan ready"
echo ""

echo "🚨 ROLLBACK PLAN:"
echo "• Backup current state before starting"
echo "• If issues occur, restore from backup"
echo "• Test each import individually"
echo ""

echo "✅ READY FOR MIGRATION!"
echo "Next step: Begin with Step 1 - Import S3 buckets"

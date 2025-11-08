#!/bin/bash

# Quick Import Script for Existing Resources
# Run this to import resources that already exist in AWS

set -e

echo "🔍 === QUICK IMPORT: Existing Resources ==="
echo ""

ZONE_ID="Z05682173V2H2T5QWU8P0"
BAILEYLESSONS_ZONE_ID="Z01009052GCOJI1M2TTF7"

# API Gateway Usage Plan (we know this exists)
echo "📋 Importing API Gateway Usage Plan..."
terraform import -var="baileylessons_admin_password=dummy" -lock=false aws_api_gateway_usage_plan.contact_form_usage_plan "cr6c0m" 2>/dev/null && echo "✅ Imported" || echo "⚠️  Already in state or failed"

echo ""
echo "📋 Importing API Gateway Usage Plan Key..."
terraform import -var="baileylessons_admin_password=dummy" -lock=false aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "cr6c0m/9udpgoq4u1" 2>/dev/null && echo "✅ Imported" || echo "⚠️  Already in state or failed"

echo ""
echo "📋 Checking Route53 Records..."
echo "Run these commands manually if the records exist:"
echo ""
echo "  # Root domain A record"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false aws_route53_record.root_domain \"${ZONE_ID}_robertconsulting.net_A\""
echo ""
echo "  # Root domain AAAA record"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false aws_route53_record.root_domain_ipv6 \"${ZONE_ID}_robertconsulting.net_AAAA\""
echo ""
echo "  # Staging domain A record"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false aws_route53_record.staging_domain \"${ZONE_ID}_staging.robertconsulting.net_A\""
echo ""

echo "📋 Checking Bailey Lessons Resources..."
echo "Run these commands if the resources exist:"
echo ""
echo "  # Find CloudFront distribution ID first:"
echo "  DIST_ID=\$(aws cloudfront list-distributions --query \"DistributionList.Items[?contains(Aliases.Items,'admin.baileylessons.com')].Id\" --output text)"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false module.baileylessons.aws_cloudfront_distribution.admin \"\$DIST_ID\""
echo ""
echo "  # Route53 record"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false module.baileylessons.aws_route53_record.admin \"${BAILEYLESSONS_ZONE_ID}_admin.baileylessons.com_A\""
echo ""
echo "  # S3 bucket policy (find bucket name first)"
echo "  BUCKET=\$(aws s3api list-buckets --query \"Buckets[?contains(Name,'baileylessons-admin')].Name\" --output text)"
echo "  terraform import -var=\"baileylessons_admin_password=dummy\" -lock=false module.baileylessons.aws_s3_bucket_policy.admin \"\$BUCKET\""
echo ""

echo "📋 Other resources to check:"
echo "  - aws_lambda_permission.contact_form_api_gateway"
echo "  - aws_wafv2_web_acl_association.contact_form_waf_association"
echo "  - aws_cloudwatch_metric_alarm.staging_high_error_rate"
echo "  - module.plex_recommendations.aws_lambda_function.plex_analyzer"
echo "  - aws_iam_role_policy.plex_lambda_s3_policy"
echo ""

echo "✅ Quick import completed!"
echo ""
echo "💡 Tip: After importing, run 'terraform plan' to see remaining changes"


#!/bin/bash

echo "🔧 === COMPREHENSIVE RESOURCE IMPORT PLAN ==="
echo ""
echo "This script will import all existing AWS resources into Terraform state"
echo "to resolve the 'ResourceAlreadyExists' errors."
echo ""

# Check if we're in the terraform directory
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the terraform/ directory"
    exit 1
fi

echo "📋 PHASE 1: Import IAM Roles"
echo "============================="

# Import IAM Roles
echo "Importing IAM roles..."
terraform import aws_iam_role.synthetics_role robert-consulting-synthetics-role
terraform import aws_iam_role.contact_form_lambda_role contact-form-lambda-role
terraform import aws_iam_role.dashboard_api_role robert-consulting-dashboard-api-role
terraform import aws_iam_role.stats_refresher_role dashboard-stats-refresher-role

echo ""
echo "📋 PHASE 2: Import WAF Resources"
echo "================================"

# Import WAF Web ACLs (need to get ARNs first)
echo "Note: WAF resources need ARNs. We'll need to get these from AWS CLI first."
echo "aws wafv2 list-web-acls --scope REGIONAL --region us-east-1"
echo "aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1"

echo ""
echo "📋 PHASE 3: Import CloudFront Resources"
echo "======================================="

# Import CloudFront Response Headers Policies
echo "Importing CloudFront response headers policies..."
# Need to get the IDs first
echo "aws cloudfront list-response-headers-policies --query 'ResponseHeadersPolicyList.Items[?Name==\`security-headers-policy\`].Id' --output text"

echo ""
echo "📋 PHASE 4: Import S3 Buckets"
echo "============================="

# Import S3 Buckets
echo "Importing S3 buckets..."
terraform import aws_s3_bucket.plex_recommendations_data plex-recommendations-data-1e15cfbc
terraform import aws_s3_bucket.terraform_state robert-consulting-terraform-state

echo ""
echo "📋 PHASE 5: Import Lambda Functions"
echo "=================================="

# Import Lambda Functions
echo "Importing Lambda functions..."
terraform import aws_lambda_function.plex_analyzer plex-analyzer
terraform import aws_lambda_function.robert_consulting_plex_analyzer robert-consulting-plex-analyzer
terraform import aws_lambda_function.terraform_stats_refresher robert-consulting-terraform-stats-refresher

echo ""
echo "📋 PHASE 6: Import Other Resources"
echo "=================================="

# Import SES Configuration Set
terraform import aws_ses_configuration_set.main robertconsulting-email-config

# Import DynamoDB Table
terraform import aws_dynamodb_table.terraform_locks robert-consulting-terraform-locks

# Import CloudWatch Log Groups
terraform import aws_cloudwatch_log_group.stats_refresher_logs /aws/lambda/dashboard-stats-refresher
terraform import aws_cloudwatch_log_group.main_site_waf_logs[0] /aws/wafv2/main-site

# Import Secrets Manager Secret
terraform import aws_secretsmanager_secret.github_token github-token-dashboard-stats

echo ""
echo "🎯 IMPORT STRATEGY:"
echo "==================="
echo "1. Run each import command individually"
echo "2. Check terraform plan after each import"
echo "3. Fix any configuration mismatches"
echo "4. Repeat until all resources are imported"
echo ""
echo "⚠️  IMPORTANT: Some resources may need configuration updates"
echo "   after import to match the existing AWS configuration."
echo ""
echo "🚀 Ready to start importing? Run the commands above one by one."

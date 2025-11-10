# Terraform Plan Analysis - Resource Catalog Implementation

**Date:** November 10, 2025

## Expected Changes (Resource Catalog)

✅ **These are expected and should be applied:**
- `aws_dynamodb_table.resource_catalog` - New catalog table
- `aws_lambda_function.resource_cataloger` - New cataloger function
- `aws_iam_role.resource_cataloger_role` - New IAM role
- `aws_iam_role_policy.resource_cataloger_policy` - New IAM policy
- `aws_cloudwatch_event_rule.resource_cataloger_schedule` - Daily schedule
- `aws_cloudwatch_event_target.resource_cataloger_target` - Event target
- `aws_lambda_permission.resource_cataloger_event` - Lambda permission
- `aws_sns_topic.resource_alerts` - Alert topic
- `aws_sns_topic_subscription.resource_alerts_email` - Email subscription
- `aws_cloudwatch_dashboard.resource_catalog` - Dashboard
- `aws_cloudwatch_metric_alarm.untagged_resources` - Alarm
- `aws_cloudwatch_metric_alarm.unused_resources` - Alarm
- `null_resource.build_resource_cataloger_package` - Build step

## Unexpected Changes (Need Review)

⚠️ **These changes are NOT related to resource catalog and need investigation:**

### 1. Route53 Records (Should Already Exist)
- `aws_route53_record.root_domain` - Should be imported
- `aws_route53_record.root_domain_ipv6` - Should be imported
- `aws_route53_record.staging_domain` - Should be imported

### 2. CloudFront Certificate Changes
- `aws_cloudfront_distribution.staging_website` - Certificate ARN change
- `aws_cloudfront_distribution.website` - Certificate ARN change + logging removal

### 3. Tag Removals
- Multiple resources removing "Project" tag
- This might be intentional if consolidating tags

### 4. Lambda Function Updates
- `aws_lambda_function.plex_analyzer` - Runtime and config changes
- `aws_lambda_function.robert_consulting_plex_analyzer` - Runtime change
- `aws_lambda_function.terraform_stats_refresher` - Runtime change
- `aws_lambda_function.dashboard_api` - Source code hash change
- `aws_lambda_function.stats_refresher` - Source code hash change

### 5. Lambda Permission Replacements
- `aws_lambda_permission.api_gateway_lambda` - Source ARN change
- `aws_lambda_permission.dashboard_api_permission` - Source ARN change

### 6. Secret Version Replacement
- `aws_secretsmanager_secret_version.admin_security` - Forces replacement

### 7. Module Resources
- `module.baileylessons.aws_cloudfront_distribution.admin` - Should exist
- `module.baileylessons.aws_route53_record.admin` - Should exist
- `module.baileylessons.aws_s3_bucket_policy.admin` - Should exist
- `module.plex_recommendations.aws_lambda_function.plex_analyzer` - New module resource

## Recommendations

1. **Import existing resources** before applying:
   - Route53 records
   - Bailey Lessons CloudFront distribution
   - Bailey Lessons Route53 record
   - Bailey Lessons S3 bucket policy

2. **Review Lambda changes** - These might be intentional updates

3. **Review CloudFront certificate changes** - Verify these are correct

4. **Review tag removals** - Confirm if "Project" tag removal is intentional

5. **Apply resource catalog changes separately** if possible to isolate issues

## Next Steps

1. Import existing resources first
2. Review and approve Lambda/CloudFront changes
3. Apply resource catalog changes
4. Verify cataloger works correctly


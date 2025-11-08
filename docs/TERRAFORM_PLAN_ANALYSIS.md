# Terraform Plan Analysis

**Date**: January 2025  
**Issue**: Plan shows many changes beyond variable refactoring

---

## Expected Changes (From Our Work)

### ✅ Variable Refactoring Changes
- **CloudWatch Dashboards**: Updating from placeholder `"CLOUDFRONT_DISTRIBUTION_ID"` to variable `var.cloudfront_distribution_id`
  - `aws_cloudwatch_dashboard.cost_monitoring` (2 widgets)
  - `aws_cloudwatch_dashboard.service_status` (4 widgets)
  - `aws_cloudwatch_dashboard.performance_monitoring` (4 widgets)
- **CloudWatch Alarms**: Updating distribution ID reference
  - `aws_cloudwatch_metric_alarm.cloudfront_error_rate`
- **Lambda Environment**: Using variable instead of hardcoded value
  - `aws_lambda_function.stats_refresher` (environment variable)

### ✅ Cost Guardrails Implementation
- **New Resources** (Expected):
  - `aws_budgets_budget.daily_cost_guardrail`
  - `aws_budgets_budget.monthly_cost_guardrail`
  - `aws_dynamodb_table.api_rate_limits`
  - `aws_dynamodb_table.api_cost_tracking`
  - `aws_sns_topic.api_cost_alerts`
  - `aws_iam_role.budget_action_role`
  - `aws_iam_policy.lambda_disable_policy`
  - `aws_iam_policy.rate_limiting_access`
  - New CloudWatch alarms for Lambda and API costs

---

## Unexpected Changes (Review Needed)

### ⚠️ CloudFront Distribution Changes
1. **`aws_cloudfront_distribution.plex_distribution`**
   - Removing aliases: `["plex.robertconsulting.net"]`
   - Changing origin from custom_origin_config to s3_origin_config
   - Changing certificate configuration
   - **Impact**: May break plex.robertconsulting.net access

2. **`aws_cloudfront_distribution.website`**
   - Removing logging_config
   - Changing certificate ARN
   - Removing "Project" tag
   - **Impact**: May affect logging and SSL certificate

3. **`aws_cloudfront_distribution.staging_website`**
   - Changing certificate ARN
   - Removing "Project" tag
   - **Impact**: May affect staging SSL certificate

### ⚠️ Lambda Function Changes
- Multiple Lambda functions showing updates (source code hash changes)
- These may be from code changes or build artifacts

### ⚠️ Other Changes
- Route53 records being created
- SNS topic subscription email changes
- Various IAM policy updates

---

## Recommended Approach

### Option 1: Targeted Apply (Safest)

Apply only the variable refactoring and cost guardrails changes:

```bash
# Apply only variable refactoring changes
terraform apply -target=aws_cloudwatch_dashboard.cost_monitoring \
  -target=aws_cloudwatch_dashboard.service_status \
  -target=aws_cloudwatch_dashboard.performance_monitoring \
  -target=aws_cloudwatch_metric_alarm.cloudfront_error_rate \
  -target=aws_lambda_function.stats_refresher

# Apply cost guardrails (new resources)
terraform apply -target=aws_budgets_budget.daily_cost_guardrail \
  -target=aws_budgets_budget.monthly_cost_guardrail \
  -target=aws_dynamodb_table.api_rate_limits \
  -target=aws_dynamodb_table.api_cost_tracking \
  -target=aws_sns_topic.api_cost_alerts \
  -target=aws_iam_role.budget_action_role \
  -target=aws_iam_policy.lambda_disable_policy \
  -target=aws_iam_policy.rate_limiting_access \
  -target=aws_iam_role_policy_attachment.budget_action_policy \
  -target=aws_sns_topic_subscription.api_cost_alerts_email \
  -target=aws_cloudwatch_metric_alarm.daily_api_cost_alert \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_duration \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_throttles \
  -target=aws_cloudwatch_metric_alarm.lambda_stats_refresher_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_high_invocations
```

### Option 2: Review and Fix Unrelated Changes

Investigate why CloudFront distributions are changing:

```bash
# Check what's different in the CloudFront config
terraform show aws_cloudfront_distribution.plex_distribution
terraform show aws_cloudfront_distribution.website
terraform show aws_cloudfront_distribution.staging_website
```

### Option 3: Full Apply (If You Trust All Changes)

If you've reviewed all changes and they're intentional:

```bash
terraform apply
```

---

## Quick Fix: Variable Refactoring Only

If you want to apply ONLY the variable refactoring (safest option):

```bash
terraform apply \
  -target=aws_cloudwatch_dashboard.cost_monitoring \
  -target=aws_cloudwatch_dashboard.service_status \
  -target=aws_cloudwatch_dashboard.performance_monitoring \
  -target=aws_cloudwatch_metric_alarm.cloudfront_error_rate \
  -target=aws_lambda_function.stats_refresher \
  -lock=false
```

This will:
- ✅ Update CloudWatch dashboards to use variable
- ✅ Update CloudWatch alarms to use variable
- ✅ Update Lambda environment variable to use variable
- ❌ Skip all other changes (cost guardrails, CloudFront, etc.)

---

## Next Steps

1. **Review the unexpected changes** - Especially CloudFront distribution changes
2. **Decide on approach** - Targeted apply vs full apply
3. **Apply changes** - Use targeted apply for safety
4. **Verify** - Check that dashboards/alarms still work after changes


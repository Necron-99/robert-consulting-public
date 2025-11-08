# Applying Cost Guardrails - Targeted Terraform Apply

**Date**: January 2025  
**Purpose**: Apply only the cost guardrails resources without affecting other infrastructure

---

## Cost Guardrails Resources

### Solution 1: AWS Budgets
- `aws_budgets_budget.daily_cost_guardrail`
- `aws_budgets_budget.monthly_cost_guardrail`
- `aws_iam_role.budget_action_role`
- `aws_iam_policy.lambda_disable_policy`
- `aws_iam_role_policy_attachment.budget_action_policy`

### Solution 2: Rate Limiting Infrastructure
- `aws_dynamodb_table.api_rate_limits`
- `aws_dynamodb_table.api_cost_tracking`
- `aws_sns_topic.api_cost_alerts`
- `aws_sns_topic_subscription.api_cost_alerts_email`
- `aws_iam_policy.rate_limiting_access`

### Additional Monitoring
- `aws_cloudwatch_metric_alarm.daily_api_cost_alert`
- `aws_cloudwatch_metric_alarm.lambda_dashboard_api_errors`
- `aws_cloudwatch_metric_alarm.lambda_dashboard_api_duration`
- `aws_cloudwatch_metric_alarm.lambda_dashboard_api_throttles`
- `aws_cloudwatch_metric_alarm.lambda_stats_refresher_errors`
- `aws_cloudwatch_metric_alarm.lambda_high_invocations`

---

## Apply Command

### Single Command (All Cost Guardrails)

```bash
cd terraform

terraform apply \
  -var="baileylessons_admin_password=dummy" \
  -target=aws_budgets_budget.daily_cost_guardrail \
  -target=aws_budgets_budget.monthly_cost_guardrail \
  -target=aws_iam_role.budget_action_role \
  -target=aws_iam_policy.lambda_disable_policy \
  -target=aws_iam_role_policy_attachment.budget_action_policy \
  -target=aws_dynamodb_table.api_rate_limits \
  -target=aws_dynamodb_table.api_cost_tracking \
  -target=aws_sns_topic.api_cost_alerts \
  -target=aws_sns_topic_subscription.api_cost_alerts_email \
  -target=aws_iam_policy.rate_limiting_access \
  -target=aws_cloudwatch_metric_alarm.daily_api_cost_alert \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_duration \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_throttles \
  -target=aws_cloudwatch_metric_alarm.lambda_stats_refresher_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_high_invocations \
  -lock=false
```

### Step-by-Step (Recommended for First Time)

#### Step 1: AWS Budgets
```bash
terraform apply \
  -var="baileylessons_admin_password=dummy" \
  -target=aws_budgets_budget.daily_cost_guardrail \
  -target=aws_budgets_budget.monthly_cost_guardrail \
  -target=aws_iam_role.budget_action_role \
  -target=aws_iam_policy.lambda_disable_policy \
  -target=aws_iam_role_policy_attachment.budget_action_policy \
  -lock=false
```

#### Step 2: Rate Limiting Infrastructure
```bash
terraform apply \
  -var="baileylessons_admin_password=dummy" \
  -target=aws_dynamodb_table.api_rate_limits \
  -target=aws_dynamodb_table.api_cost_tracking \
  -target=aws_sns_topic.api_cost_alerts \
  -target=aws_sns_topic_subscription.api_cost_alerts_email \
  -target=aws_iam_policy.rate_limiting_access \
  -lock=false
```

#### Step 3: CloudWatch Monitoring Alarms
```bash
terraform apply \
  -var="baileylessons_admin_password=dummy" \
  -target=aws_cloudwatch_metric_alarm.daily_api_cost_alert \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_duration \
  -target=aws_cloudwatch_metric_alarm.lambda_dashboard_api_throttles \
  -target=aws_cloudwatch_metric_alarm.lambda_stats_refresher_errors \
  -target=aws_cloudwatch_metric_alarm.lambda_high_invocations \
  -lock=false
```

---

## Verify Deployment

### Check Budgets
```bash
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name daily-cost-guardrail

aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name monthly-cost-guardrail
```

### Check DynamoDB Tables
```bash
aws dynamodb describe-table --table-name api-rate-limits
aws dynamodb describe-table --table-name api-cost-tracking
```

### Check SNS Topic
```bash
aws sns get-topic-attributes --topic-arn $(aws sns list-topics --query 'Topics[?contains(TopicArn, `api-cost-alerts`)].TopicArn' --output text)
```

### Check CloudWatch Alarms
```bash
aws cloudwatch describe-alarms --alarm-names \
  robert-consulting-daily-api-cost-alert \
  robert-consulting-lambda-dashboard-api-errors \
  robert-consulting-lambda-dashboard-api-duration \
  robert-consulting-lambda-dashboard-api-throttles \
  robert-consulting-lambda-stats-refresher-errors \
  robert-consulting-lambda-high-invocations
```

---

## Expected Outputs

After applying, you should see these outputs:

```
budget_daily_arn = "arn:aws:budgets::ACCOUNT_ID:budget/daily-cost-guardrail"
budget_monthly_arn = "arn:aws:budgets::ACCOUNT_ID:budget/monthly-cost-guardrail"
rate_limiting_table_name = "api-rate-limits"
cost_tracking_table_name = "api-cost-tracking"
api_cost_alerts_topic_arn = "arn:aws:sns:us-east-1:ACCOUNT_ID:api-cost-alerts"
```

---

## Notes

1. **Email Confirmation**: You'll receive an email to confirm the SNS subscription for `api_cost_alerts_email`. Click the confirmation link.

2. **Budget Notifications**: Budget notifications may take a few minutes to activate. You'll receive test emails when budgets are created.

3. **DynamoDB Costs**: Tables use on-demand billing, so costs are minimal (~$0.10-0.50/month).

4. **IAM Policy**: The `rate_limiting_access` policy is created but not attached to any Lambda roles yet. You'll need to attach it when integrating the rate limiter into Lambda functions.

---

## Troubleshooting

### If Budget Creation Fails
- Ensure you have billing access enabled in your AWS account
- Check IAM permissions for budgets:CreateBudget

### If DynamoDB Creation Fails
- Verify you're within DynamoDB service quotas
- Check IAM permissions for dynamodb:CreateTable

### If SNS Subscription Fails
- Check email address is valid
- Verify SNS service quotas

---

## Next Steps

After applying cost guardrails:

1. **Integrate Rate Limiter**: Update Lambda functions to use the rate limiting utility
2. **Attach IAM Policy**: Attach `rate_limiting_access` policy to Lambda execution roles
3. **Test Alarms**: Verify CloudWatch alarms are in OK state
4. **Monitor**: Check CloudWatch dashboards for cost metrics

See [Cost Guardrails Implementation Guide](./COST_GUARDRAILS_IMPLEMENTATION.md) for integration details.


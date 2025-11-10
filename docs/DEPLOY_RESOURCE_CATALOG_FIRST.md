# Deploy Resource Catalog First

## Overview

When you have a large Terraform plan with many resources, you may want to deploy the Resource Catalog infrastructure first. This allows you to:

1. Deploy the cataloger and its dependencies
2. Run the cataloger to generate the Terraform resource ARN list
3. Import remaining resources using the generated import commands

## Quick Start

### Option 1: Use the deployment script (Recommended)

```bash
./scripts/deploy-resource-catalog-only.sh
```

This script will:
- Show you what will be deployed
- Import existing CloudWatch alarms if they exist
- Create a targeted plan
- Ask for confirmation before applying

### Option 2: Manual targeting

```bash
cd terraform

# Plan with targets
terraform plan \
  -target=aws_dynamodb_table.resource_catalog \
  -target=aws_iam_role.resource_cataloger_role \
  -target=aws_iam_role_policy.resource_cataloger_policy \
  -target=aws_lambda_function.resource_cataloger \
  -target=aws_lambda_permission.resource_cataloger_event \
  -target=aws_cloudwatch_event_rule.resource_cataloger_schedule \
  -target=aws_cloudwatch_event_target.resource_cataloger_target \
  -target=aws_cloudwatch_dashboard.resource_catalog \
  -target=aws_cloudwatch_metric_alarm.untagged_resources \
  -target=aws_cloudwatch_metric_alarm.unused_resources \
  -target=aws_sns_topic.resource_alerts \
  -target=aws_sns_topic_subscription.resource_alerts_email \
  -target=null_resource.generate_terraform_arns \
  -target=null_resource.copy_terraform_arns \
  -target=null_resource.build_resource_cataloger_package \
  -out=resource-catalog.tfplan

# Review the plan
terraform show resource-catalog.tfplan

# Apply
terraform apply resource-catalog.tfplan
```

### Option 3: Generate commands

```bash
./scripts/terraform-target-resource-catalog.sh
```

## Resources Included

The following resources are targeted:

### Core Infrastructure
- `aws_dynamodb_table.resource_catalog` - Catalog storage
- `aws_iam_role.resource_cataloger_role` - Lambda execution role
- `aws_iam_role_policy.resource_cataloger_policy` - Lambda permissions
- `aws_lambda_function.resource_cataloger` - Cataloger function
- `aws_lambda_permission.resource_cataloger_event` - EventBridge permission

### Scheduling
- `aws_cloudwatch_event_rule.resource_cataloger_schedule` - Daily schedule
- `aws_cloudwatch_event_target.resource_cataloger_target` - Event target

### Monitoring
- `aws_cloudwatch_dashboard.resource_catalog` - Dashboard
- `aws_cloudwatch_metric_alarm.untagged_resources` - Untagged resources alarm
- `aws_cloudwatch_metric_alarm.unused_resources` - Unused resources alarm
- `aws_sns_topic.resource_alerts` - Alert topic
- `aws_sns_topic_subscription.resource_alerts_email` - Email subscription

### Build Steps
- `null_resource.generate_terraform_arns` - Generate ARN list
- `null_resource.copy_terraform_arns` - Copy to Lambda
- `null_resource.build_resource_cataloger_package` - Build Lambda package

## After Deployment

1. **Wait for the cataloger to run** (or trigger it manually):
   ```bash
   aws lambda invoke \
     --function-name robert-consulting-resource-cataloger \
     --payload '{}' \
     response.json
   ```

2. **Generate Terraform ARN list** (if not auto-generated):
   ```bash
   node scripts/generate-terraform-resource-list.js
   ```

3. **Import remaining resources**:
   ```bash
   # Review the import commands
   cat terraform-import-commands.sh
   
   # Run imports (one at a time recommended)
   bash terraform-import-commands.sh
   ```

4. **Run full plan** to verify:
   ```bash
   cd terraform
   terraform plan
   ```

## Notes

- The script will attempt to import existing CloudWatch alarms if they exist
- Some resources may show as "MANUAL CHECK REQUIRED" but are likely new (e.g., SNS topics, event targets)
- The cataloger needs to run at least once to generate the Terraform ARN list
- After the cataloger runs, it will only catalog Terraform-managed resources


#!/bin/bash

# Generate terraform target commands for resource catalog only
# Usage: ./scripts/terraform-target-resource-catalog.sh

cat << 'EOF'
# Terraform commands to deploy Resource Catalog infrastructure only

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

# Apply
terraform apply resource-catalog.tfplan

# Or apply directly (without saving plan)
terraform apply \
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
  -target=null_resource.build_resource_cataloger_package
EOF


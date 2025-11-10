#!/bin/bash

# Deploy only Resource Catalog infrastructure
# This allows deploying the cataloger first, then importing remaining resources

set -e

echo "🎯 Deploying Resource Catalog Infrastructure Only"
echo "=================================================="
echo ""

cd terraform || exit 1

# Resource Catalog resources to deploy
RESOURCES=(
  # Core catalog infrastructure
  "aws_dynamodb_table.resource_catalog"
  "aws_iam_role.resource_cataloger_role"
  "aws_iam_role_policy.resource_cataloger_policy"
  "aws_lambda_function.resource_cataloger"
  "aws_lambda_permission.resource_cataloger_event"
  
  # Scheduling and triggers
  "aws_cloudwatch_event_rule.resource_cataloger_schedule"
  "aws_cloudwatch_event_target.resource_cataloger_target"
  
  # Monitoring and alerts
  "aws_cloudwatch_dashboard.resource_catalog"
  "aws_cloudwatch_metric_alarm.untagged_resources"
  "aws_cloudwatch_metric_alarm.unused_resources"
  "aws_sns_topic.resource_alerts"
  "aws_sns_topic_subscription.resource_alerts_email"
  
  # Build steps (dependencies)
  "null_resource.generate_terraform_arns"
  "null_resource.copy_terraform_arns"
  "null_resource.build_resource_cataloger_package"
  
  # Data sources (dependencies)
  "data.archive_file.resource_cataloger_zip"
)

echo "📋 Resources to deploy:"
for resource in "${RESOURCES[@]}"; do
  echo "   - $resource"
done
echo ""

# Check if we should import existing alarms first
echo "🔍 Checking for existing CloudWatch alarms to import..."
if terraform state show aws_cloudwatch_metric_alarm.untagged_resources >/dev/null 2>&1; then
  echo "   ✅ untagged_resources alarm already in state"
else
  echo "   📥 Importing untagged_resources alarm..."
  terraform import -target=aws_cloudwatch_metric_alarm.untagged_resources robert-consulting-untagged-resources || echo "   ⚠️  Import failed (may not exist yet)"
fi

if terraform state show aws_cloudwatch_metric_alarm.unused_resources >/dev/null 2>&1; then
  echo "   ✅ unused_resources alarm already in state"
else
  echo "   📥 Importing unused_resources alarm..."
  terraform import -target=aws_cloudwatch_metric_alarm.unused_resources robert-consulting-unused-resources || echo "   ⚠️  Import failed (may not exist yet)"
fi
echo ""

# Plan with targets
echo "📊 Running terraform plan for resource catalog..."
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

echo ""
echo "✅ Plan created: resource-catalog.tfplan"
echo ""
read -p "Apply this plan? (yes/no): " -r
echo ""

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "🚀 Applying resource catalog infrastructure..."
  terraform apply resource-catalog.tfplan
  
  echo ""
  echo "✅ Resource catalog deployed!"
  echo ""
  echo "📋 Next steps:"
  echo "   1. Run the cataloger to generate Terraform ARN list"
  echo "   2. Import remaining resources using: terraform-import-commands.sh"
  echo "   3. Run full terraform plan to verify"
else
  echo "⏭️  Skipped apply. Plan saved to resource-catalog.tfplan"
  echo "   Run: terraform apply resource-catalog.tfplan"
fi


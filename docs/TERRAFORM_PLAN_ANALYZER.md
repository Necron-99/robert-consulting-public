# Terraform Plan Analyzer

## Overview

The Terraform Plan Analyzer helps determine whether resources in a Terraform plan should be **created** (new resources) or **imported** (existing resources that need to be brought under Terraform management).

## Usage

### Method 1: JavaScript Analyzer (Recommended)

```bash
# Generate plan JSON
cd terraform
terraform plan -out=tfplan
terraform show -json tfplan > ../terraform-plan.json
cd ..

# Analyze the plan
node scripts/analyze-terraform-plan.js terraform-plan.json
```

### Method 2: Shell Script Analyzer

```bash
# Auto-generate and analyze
./scripts/analyze-terraform-plan.sh auto

# Or analyze existing plan file
terraform plan > terraform-plan.txt
./scripts/analyze-terraform-plan.sh terraform-plan.txt
```

## What It Does

1. **Parses Terraform plan** to identify resources marked for creation
2. **Checks AWS** to see if each resource already exists
3. **Categorizes resources** into:
   - ✅ **To Import**: Resources that exist and should be imported
   - 🆕 **To Create**: New resources that should be created
   - ⚠️ **To Check**: Resources requiring manual review

4. **Generates import commands** in `terraform-import-commands.sh`

## Supported Resource Types

The analyzer can automatically check:
- `aws_s3_bucket`
- `aws_cloudfront_distribution`
- `aws_lambda_function`
- `aws_route53_record`
- `aws_route53_zone`
- `aws_api_gateway_rest_api`
- `aws_iam_role`
- `aws_dynamodb_table`
- `aws_sns_topic`

Other resource types will be flagged for manual review.

## Example Output

```
🔍 Analyzing Terraform Plan...

📋 aws_route53_record.root_domain
   Type: aws_route53_record
   ID: Z05682173V2H2T5QWU8P0
   Status: EXISTS - Should be IMPORTED
   → Import: terraform import aws_route53_record.root_domain Z05682173V2H2T5QWU8P0_robertconsulting.net_A

📋 aws_dynamodb_table.resource_catalog
   Type: aws_dynamodb_table
   ID: robert-consulting-resource-catalog
   Status: NEW - Should be CREATED

==========================
📊 Summary:

   Resources to IMPORT: 3
   Resources to CREATE: 15
   Resources to CHECK: 2
```

## Import Commands

After analysis, review and run:

```bash
# Review the generated commands
cat terraform-import-commands.sh

# Run imports (one at a time recommended)
bash terraform-import-commands.sh
```

## Best Practices

1. **Review before importing**: Always review the generated import commands
2. **Import one at a time**: Import resources individually to catch errors early
3. **Verify after import**: Run `terraform plan` after each import to verify
4. **Manual review**: Check resources flagged for manual review before proceeding

## Troubleshooting

### "Plan file not found"
Generate the plan JSON first:
```bash
cd terraform
terraform plan -out=tfplan
terraform show -json tfplan > ../terraform-plan.json
```

### "Cannot determine resource ID"
Some resources need manual inspection. Check the Terraform plan output or AWS console to find the resource ID.

### "Resource exists but import fails"
- Verify the import ID format matches Terraform's expected format
- Check AWS CLI permissions
- Some resources may need special import syntax (check Terraform docs)

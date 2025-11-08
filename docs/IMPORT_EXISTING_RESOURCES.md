# Import Existing Resources Guide

**Date**: January 2025  
**Purpose**: Import resources that already exist in AWS but aren't in Terraform state

---

## Overview

Several resources in the Terraform plan already exist in AWS and just need to be imported into Terraform state. This guide helps identify and import them.

---

## Resources That Likely Need Import

### Route53 Records

These Route53 records likely already exist:

1. **Root Domain A Record** (`robertconsulting.net`)
   ```bash
   terraform import aws_route53_record.root_domain "Z05682173V2H2T5QWU8P0_robertconsulting.net_A"
   ```

2. **Root Domain AAAA Record** (`robertconsulting.net` IPv6)
   ```bash
   terraform import aws_route53_record.root_domain_ipv6 "Z05682173V2H2T5QWU8P0_robertconsulting.net_AAAA"
   ```

3. **Staging Domain A Record** (`staging.robertconsulting.net`)
   ```bash
   terraform import aws_route53_record.staging_domain "Z05682173V2H2T5QWU8P0_staging.robertconsulting.net_A"
   ```

### Bailey Lessons Resources

1. **CloudFront Distribution**
   ```bash
   # First, find the distribution ID
   DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items,'admin.baileylessons.com')].Id" --output text)
   terraform import module.baileylessons.aws_cloudfront_distribution.admin "$DIST_ID"
   ```

2. **Route53 Record**
   ```bash
   terraform import module.baileylessons.aws_route53_record.admin "Z01009052GCOJI1M2TTF7_admin.baileylessons.com_A"
   ```

3. **S3 Bucket Policy**
   ```bash
   # Find the bucket name first
   BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name,'baileylessons-admin')].Name" --output text)
   terraform import module.baileylessons.aws_s3_bucket_policy.admin "$BUCKET"
   ```

### API Gateway Resources

1. **Usage Plan**
   ```bash
   # Check if usage plan exists
   USAGE_PLAN_ID=$(aws apigateway get-usage-plans --query "items[?name=='contact-form-usage-plan'].id" --output text)
   if [ ! -z "$USAGE_PLAN_ID" ]; then
     terraform import aws_api_gateway_usage_plan.contact_form_usage_plan "$USAGE_PLAN_ID"
   fi
   ```

2. **Usage Plan Key**
   ```bash
   if [ ! -z "$USAGE_PLAN_ID" ]; then
     terraform import aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "${USAGE_PLAN_ID}/9udpgoq4u1"
   fi
   ```

3. **Lambda Permission**
   ```bash
   terraform import aws_lambda_permission.contact_form_api_gateway "AllowExecutionFromAPIGateway"
   ```

### WAF Associations

1. **Contact Form WAF Association**
   ```bash
   terraform import aws_wafv2_web_acl_association.contact_form_waf_association "arn:aws:apigateway:us-east-1::/restapis/4a01s5j8f5/stages/prod"
   ```

### CloudWatch Alarms

1. **Staging High Error Rate**
   ```bash
   terraform import aws_cloudwatch_metric_alarm.staging_high_error_rate "staging-high-error-rate"
   ```

### Lambda Functions

1. **Plex Analyzer (Module)**
   ```bash
   terraform import module.plex_recommendations.aws_lambda_function.plex_analyzer "plex-recommendations-analyzer"
   ```

2. **Plex Lambda S3 Policy**
   ```bash
   terraform import aws_iam_role_policy.plex_lambda_s3_policy "plex-lambda-role:plex-s3-access"
   ```

---

## Automated Import Script

Use the provided script to automatically check and import existing resources:

```bash
cd terraform
./import-existing-resources-from-plan.sh
```

The script will:
1. Check if each resource exists in AWS
2. Import it if it exists
3. Warn if it doesn't exist (will be created on apply)

---

## Manual Import Process

### Step 1: Check What Exists

```bash
# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id Z05682173V2H2T5QWU8P0 \
  --query "ResourceRecordSets[?Type=='A' || Type=='AAAA'].{Name:Name,Type:Type}"

# Check CloudFront distributions
aws cloudfront list-distributions \
  --query "DistributionList.Items[].{Id:Id,DomainName:DomainName,Aliases:Aliases.Items}"

# Check API Gateway usage plans
aws apigateway get-usage-plans

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-name-prefix "staging-"
```

### Step 2: Import Resources

Import resources one at a time, starting with the least critical:

```bash
# Route53 records (safe to import)
terraform import aws_route53_record.root_domain "Z05682173V2H2T5QWU8P0_robertconsulting.net_A"
terraform import aws_route53_record.root_domain_ipv6 "Z05682173V2H2T5QWU8P0_robertconsulting.net_AAAA"
terraform import aws_route53_record.staging_domain "Z05682173V2H2T5QWU8P0_staging.robertconsulting.net_A"

# API Gateway resources
USAGE_PLAN_ID=$(aws apigateway get-usage-plans --query "items[?name=='contact-form-usage-plan'].id" --output text)
terraform import aws_api_gateway_usage_plan.contact_form_usage_plan "$USAGE_PLAN_ID"
terraform import aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "${USAGE_PLAN_ID}/9udpgoq4u1"

# Lambda permissions (if they exist)
terraform import aws_lambda_permission.contact_form_api_gateway "AllowExecutionFromAPIGateway"

# WAF associations
terraform import aws_wafv2_web_acl_association.contact_form_waf_association "arn:aws:apigateway:us-east-1::/restapis/4a01s5j8f5/stages/prod"

# CloudWatch alarms
terraform import aws_cloudwatch_metric_alarm.staging_high_error_rate "staging-high-error-rate"

# Lambda functions
terraform import module.plex_recommendations.aws_lambda_function.plex_analyzer "plex-recommendations-analyzer"
terraform import aws_iam_role_policy.plex_lambda_s3_policy "plex-lambda-role:plex-s3-access"
```

### Step 3: Verify Imports

```bash
# Check what's now in state
terraform state list | grep -E "(route53_record|api_gateway|waf|cloudwatch_metric_alarm|lambda)"

# Verify a specific resource
terraform state show aws_route53_record.root_domain
```

### Step 4: Re-run Plan

```bash
terraform plan -lock=false
```

The plan should now show fewer resources to create.

---

## Import Format Reference

### Route53 Records
```
terraform import aws_route53_record.<name> "<zone_id>_<record_name>_<type>"
```

### API Gateway Usage Plans
```
terraform import aws_api_gateway_usage_plan.<name> "<usage_plan_id>"
```

### API Gateway Usage Plan Keys
```
terraform import aws_api_gateway_usage_plan_key.<name> "<usage_plan_id>/<key_id>"
```

### Lambda Permissions
```
terraform import aws_lambda_permission.<name> "<statement_id>"
```

### WAF Associations
```
terraform import aws_wafv2_web_acl_association.<name> "<resource_arn>"
```

### CloudWatch Alarms
```
terraform import aws_cloudwatch_metric_alarm.<name> "<alarm_name>"
```

### Lambda Functions
```
terraform import aws_lambda_function.<name> "<function_name>"
```

### IAM Role Policies
```
terraform import aws_iam_role_policy.<name> "<role_name>:<policy_name>"
```

---

## Troubleshooting

### Import Fails: Resource Already in State

If you get "resource already managed by Terraform":
```bash
# Check if it's in state
terraform state list | grep <resource_name>

# Show the resource
terraform state show <resource_type>.<resource_name>
```

### Import Fails: Resource Doesn't Exist

If the resource doesn't exist in AWS, Terraform will create it on apply. This is fine - just skip the import.

### Import Fails: Wrong Format

Check the Terraform documentation for the correct import format:
```bash
terraform import -help
```

---

## After Importing

1. **Run Plan Again**:
   ```bash
   terraform plan -lock=false
   ```

2. **Review Changes**: The plan should show fewer "create" actions

3. **Apply Remaining Changes**: Apply only the resources that truly need to be created

---

## Quick Import Checklist

- [ ] Route53 root domain A record
- [ ] Route53 root domain AAAA record  
- [ ] Route53 staging domain A record
- [ ] Bailey Lessons CloudFront distribution
- [ ] Bailey Lessons Route53 record
- [ ] Bailey Lessons S3 bucket policy
- [ ] API Gateway usage plan
- [ ] API Gateway usage plan key
- [ ] Lambda permission (contact form)
- [ ] WAF association (contact form)
- [ ] CloudWatch alarm (staging)
- [ ] Plex Lambda function (module)
- [ ] Plex Lambda S3 policy

---

## Related Documentation

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [Terraform Plan Analysis](./TERRAFORM_PLAN_ANALYSIS.md)


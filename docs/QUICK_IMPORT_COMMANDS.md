# Quick Import Commands

**Date**: January 2025  
**Purpose**: Import existing AWS resources that Terraform wants to create

---

## Resources to Import

Based on the Terraform plan, these resources likely already exist and need to be imported:

### ✅ Confirmed to Exist

1. **API Gateway Usage Plan** - Already exists (ID: `cr6c0m`)
   ```bash
   terraform import -var="baileylessons_admin_password=dummy" -lock=false \
     aws_api_gateway_usage_plan.contact_form_usage_plan "cr6c0m"
   ```

2. **API Gateway Usage Plan Key**
   ```bash
   terraform import -var="baileylessons_admin_password=dummy" -lock=false \
     aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "cr6c0m/9udpgoq4u1"
   ```

### 🔍 Check Before Importing

Run these commands to check if resources exist, then import if they do:

#### Route53 Records

```bash
# Check if records exist
aws route53 list-resource-record-sets --hosted-zone-id Z05682173V2H2T5QWU8P0 \
  --query "ResourceRecordSets[?Name=='robertconsulting.net.' || Name=='staging.robertconsulting.net.'].{Name:Name,Type:Type}"

# If they exist, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_route53_record.root_domain "Z05682173V2H2T5QWU8P0_robertconsulting.net_A"

terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_route53_record.root_domain_ipv6 "Z05682173V2H2T5QWU8P0_robertconsulting.net_AAAA"

terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_route53_record.staging_domain "Z05682173V2H2T5QWU8P0_staging.robertconsulting.net_A"
```

#### Bailey Lessons CloudFront Distribution

```bash
# Check if distribution exists
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Aliases.Items,'admin.baileylessons.com')].Id" \
  --output text)

if [ ! -z "$DIST_ID" ]; then
  terraform import -var="baileylessons_admin_password=dummy" -lock=false \
    module.baileylessons.aws_cloudfront_distribution.admin "$DIST_ID"
fi
```

#### Bailey Lessons Route53 Record

```bash
# Check if record exists
aws route53 list-resource-record-sets --hosted-zone-id Z01009052GCOJI1M2TTF7 \
  --query "ResourceRecordSets[?Name=='admin.baileylessons.com.' && Type=='A']"

# If exists, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  module.baileylessons.aws_route53_record.admin "Z01009052GCOJI1M2TTF7_admin.baileylessons.com_A"
```

#### Bailey Lessons S3 Bucket Policy

```bash
# Find bucket
BUCKET=$(aws s3api list-buckets \
  --query "Buckets[?contains(Name,'baileylessons-admin')].Name" \
  --output text)

if [ ! -z "$BUCKET" ]; then
  terraform import -var="baileylessons_admin_password=dummy" -lock=false \
    module.baileylessons.aws_s3_bucket_policy.admin "$BUCKET"
fi
```

#### Lambda Permission (Contact Form)

```bash
# Check if permission exists
aws lambda get-policy --function-name contact-form-api \
  --query 'Policy' --output text | grep -q "AllowExecutionFromAPIGateway" && \
  terraform import -var="baileylessons_admin_password=dummy" -lock=false \
    aws_lambda_permission.contact_form_api_gateway "AllowExecutionFromAPIGateway" || \
  echo "Permission not found, will be created"
```

#### WAF Association

```bash
# Check if WAF is associated
aws wafv2 list-resources-for-web-acl \
  --web-acl-arn "arn:aws:wafv2:us-east-1:228480945348:regional/webacl/contact-form-waf/80b89e94-d5b4-4f92-a31d-1f5c0290c1db" \
  --resource-type APIGATEWAY \
  --query "ResourceArns[?contains(@,'4a01s5j8f5')]"

# If associated, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_wafv2_web_acl_association.contact_form_waf_association \
  "arn:aws:apigateway:us-east-1::/restapis/4a01s5j8f5/stages/prod"
```

#### CloudWatch Alarm

```bash
# Check if alarm exists
aws cloudwatch describe-alarms --alarm-names "staging-high-error-rate" \
  --query "MetricAlarms[0].AlarmName" --output text

# If exists, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_cloudwatch_metric_alarm.staging_high_error_rate "staging-high-error-rate"
```

#### Plex Lambda Function (Module)

```bash
# Check if function exists
aws lambda get-function --function-name plex-recommendations-analyzer \
  --query 'Configuration.FunctionName' --output text

# If exists, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  module.plex_recommendations.aws_lambda_function.plex_analyzer \
  "plex-recommendations-analyzer"
```

#### Plex Lambda S3 Policy

```bash
# Check if policy exists
aws iam list-role-policies --role-name plex-lambda-role \
  --query "PolicyNames[?@=='plex-s3-access']" --output text

# If exists, import:
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_iam_role_policy.plex_lambda_s3_policy "plex-lambda-role:plex-s3-access"
```

---

## All-in-One Import Script

Run this to import all confirmed resources:

```bash
cd terraform

# API Gateway resources (confirmed to exist)
terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_api_gateway_usage_plan.contact_form_usage_plan "cr6c0m"

terraform import -var="baileylessons_admin_password=dummy" -lock=false \
  aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "cr6c0m/9udpgoq4u1"

# Then check and import others as needed (see commands above)
```

---

## After Importing

1. **Run Plan Again**:
   ```bash
   terraform plan -var="baileylessons_admin_password=dummy" -lock=false
   ```

2. **Verify**: The plan should show fewer resources to create

3. **Apply Remaining**: Apply only resources that truly need to be created

---

## Notes

- The `-var="baileylessons_admin_password=dummy"` flag is needed to skip the variable prompt
- Some resources may not exist yet - that's fine, Terraform will create them
- Import errors are OK if the resource is already in state or doesn't exist
- Always verify with `terraform plan` after importing


# Terraform DRY Refactoring - CloudFront Distribution ID

**Date**: January 2025  
**Status**: ✅ **COMPLETED**  
**Purpose**: Extract hardcoded CloudFront distribution ID to Terraform variable following DRY principles

---

## Summary

Refactored Terraform configuration to use a centralized variable for the CloudFront distribution ID, eliminating hardcoded values across multiple files and following Infrastructure as Code best practices.

---

## Changes Made

### 1. Created Central Variables File

**File**: `terraform/variables.tf` (NEW)

Defined centralized variables:
- `cloudfront_distribution_id` - CloudFront distribution ID with validation
- `main_site_bucket_name` - S3 bucket name for main website
- `alert_email` - Email for monitoring alerts
- `monitoring_enabled` - Enable/disable monitoring

**Key Features**:
- Default value: `"E36DBYPHUUKB3V"` (maintains backward compatibility)
- Validation rule to ensure correct format
- Clear descriptions for each variable

### 2. Created Example Variables File

**File**: `terraform/terraform.tfvars.example` (NEW)

Provides example configuration showing how to override defaults:
- Copy to `terraform.tfvars` (gitignored) to customize
- Documents all available variables
- Shows default values

### 3. Updated All Terraform Files

Replaced hardcoded `"E36DBYPHUUKB3V"` with `var.cloudfront_distribution_id` in:

#### Files Updated:
1. **`terraform/cloudwatch-dashboards.tf`**
   - All CloudFront metric references (10+ instances)
   - S3 bucket name references
   - Alert email configuration

2. **`terraform/main-site-monitoring.tf`**
   - All CloudFront alarm dimensions (5 instances)

3. **`terraform/main-site-dashboard.tf`**
   - All CloudFront dashboard metrics (3 instances)

4. **`terraform/lambda-stats-refresher.tf`**
   - Lambda environment variable
   - IAM policy resource ARN

---

## Benefits

### ✅ DRY Principle
- Single source of truth for CloudFront distribution ID
- Changes only need to be made in one place
- Reduced risk of inconsistencies

### ✅ Flexibility
- Easy to override for different environments
- Can use `terraform.tfvars` for environment-specific values
- Can use environment variables or CLI flags

### ✅ Best Practices
- Follows Terraform variable conventions
- Includes validation rules
- Proper documentation
- Example file for reference

### ✅ Maintainability
- Clear variable names and descriptions
- Easy to find and update
- Type safety with validation

---

## Usage

### Default Behavior (No Changes Required)

The default value is set, so existing deployments continue to work:

```bash
terraform plan
terraform apply
```

### Override via terraform.tfvars

Create `terraform/terraform.tfvars`:

```hcl
cloudfront_distribution_id = "E36DBYPHUUKB3V"
main_site_bucket_name = "robert-consulting-website"
alert_email = "rsbailey@necron99.org"
```

### Override via Environment Variable

```bash
export TF_VAR_cloudfront_distribution_id="E36DBYPHUUKB3V"
terraform apply
```

### Override via CLI Flag

```bash
terraform apply -var="cloudfront_distribution_id=E36DBYPHUUKB3V"
```

### Override via tfvars File

```bash
terraform apply -var-file="production.tfvars"
```

---

## Variable Reference

### `cloudfront_distribution_id`

- **Type**: `string`
- **Default**: `"E36DBYPHUUKB3V"`
- **Description**: CloudFront distribution ID for the main website
- **Validation**: Must match pattern `^E[A-Z0-9]{13}$`
- **Used In**:
  - CloudWatch dashboards
  - CloudWatch alarms
  - Lambda environment variables
  - IAM policy resource ARNs

### `main_site_bucket_name`

- **Type**: `string`
- **Default**: `"robert-consulting-website"`
- **Description**: S3 bucket name for the main website
- **Used In**:
  - CloudWatch dashboards
  - CloudWatch alarms

### `alert_email`

- **Type**: `string`
- **Default**: `"rsbailey@necron99.org"`
- **Description**: Email address for receiving monitoring alerts
- **Used In**:
  - SNS topic subscriptions

### `monitoring_enabled`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable comprehensive monitoring
- **Used In**:
  - Conditional resource creation

---

## Files Changed

### New Files
- ✅ `terraform/variables.tf`
- ✅ `terraform/terraform.tfvars.example`

### Modified Files
- ✅ `terraform/cloudwatch-dashboards.tf`
- ✅ `terraform/main-site-monitoring.tf`
- ✅ `terraform/main-site-dashboard.tf`
- ✅ `terraform/lambda-stats-refresher.tf`

### Files with Remaining Hardcoded References (OK)
- `terraform/terraform.tfvars.example` - Example file (intentional)
- `terraform/variables.tf` - Default value (intentional)
- `terraform/temp-env.json` - Temporary file
- `terraform/import-resources.sh` - Import script (one-time use)

---

## Validation

### Terraform Validation

```bash
cd terraform
terraform validate
```

### Syntax Check

```bash
terraform fmt -check
terraform fmt -diff
```

### Plan Verification

```bash
terraform plan
# Should show no changes if using default values
```

---

## Migration Notes

### Backward Compatibility

✅ **Fully backward compatible** - Default values match previous hardcoded values

### No Breaking Changes

- Existing Terraform state remains valid
- No resources need to be recreated
- No manual intervention required

### Recommended Next Steps

1. **Review variables**: Check if defaults match your environment
2. **Create terraform.tfvars**: If you need environment-specific values
3. **Update CI/CD**: If using GitHub Actions, consider using GitHub secrets
4. **Document overrides**: Note any environment-specific values

---

## GitHub Secrets (Optional)

If you want to use GitHub secrets instead of terraform.tfvars:

### GitHub Actions Example

```yaml
- name: Terraform Apply
  env:
    TF_VAR_cloudfront_distribution_id: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}
  run: terraform apply -auto-approve
```

### When to Use GitHub Secrets

- ✅ Sensitive values (though distribution ID is not sensitive)
- ✅ Values that differ between environments
- ✅ Values you don't want in version control

### When to Use Terraform Variables

- ✅ Non-sensitive configuration
- ✅ Values with sensible defaults
- ✅ Values that benefit from validation
- ✅ **This use case** - Distribution ID is not sensitive

---

## Best Practices Applied

1. ✅ **Single Source of Truth**: One variable definition
2. ✅ **Validation**: Format validation on variable
3. ✅ **Documentation**: Clear descriptions and examples
4. ✅ **Default Values**: Backward compatible defaults
5. ✅ **Type Safety**: Explicit type declarations
6. ✅ **DRY Principle**: No code duplication

---

## Related Documentation

- [Terraform Variables Documentation](https://www.terraform.io/docs/language/values/variables.html)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Cost Guardrails Implementation](./COST_GUARDRAILS_IMPLEMENTATION.md)

---

## Verification Checklist

- [x] All hardcoded distribution IDs replaced with variable
- [x] Default value matches previous hardcoded value
- [x] Variable validation added
- [x] Example tfvars file created
- [x] All Terraform files validate
- [x] No breaking changes
- [x] Documentation updated

---

## Conclusion

The Terraform configuration is now more maintainable, flexible, and follows Infrastructure as Code best practices. The CloudFront distribution ID can be easily changed for different environments without modifying multiple files.


# S3 Bucket Analysis - Usage and Terraform State

## Buckets in Terraform State ✅

### Production Website
- **`robert-consulting-website`** ✅
  - **Terraform**: `aws_s3_bucket.website_bucket`
  - **Purpose**: Main production website hosting
  - **Status**: ✅ **ACTIVE** - In use

### Admin Site
- **`rc-admin-site-1aaef0`** ✅
  - **Terraform**: `aws_s3_bucket.admin`
  - **Purpose**: Admin site (Clients Admin Hub)
  - **Status**: ✅ **ACTIVE** - In use

### Staging Environment
- **`robert-consulting-staging-website`** ✅
  - **Terraform**: `aws_s3_bucket.staging_website_bucket`
  - **Purpose**: Staging website hosting
  - **Status**: ✅ **ACTIVE** - In use

- **`robert-consulting-staging-access-logs`** ✅
  - **Terraform**: `aws_s3_bucket.staging_access_logs`
  - **Purpose**: CloudFront access logs for staging
  - **Status**: ✅ **ACTIVE** - Has content (access-logs/)

### Plex Recommendations
- **`plex.robertconsulting.net`** ✅ (DUPLICATE IN STATE)
  - **Terraform**: `aws_s3_bucket.plex_domain` (orphaned-resources.tf) AND `module.plex_recommendations.aws_s3_bucket.plex_domain`
  - **Purpose**: Plex domain hosting
  - **Status**: ✅ **ACTIVE** - Has content (website/)
  - **Issue**: ⚠️ Defined in both orphaned-resources.tf and module - should consolidate

- **`plex-recommendations-c7c49ce4`** ✅
  - **Terraform**: `module.plex_recommendations.aws_s3_bucket.plex_data`
  - **Purpose**: Plex data storage
  - **Status**: ✅ **ACTIVE** - Has content (plex-data/, plex-recommendations/)

- **`plex-recommendations-data-1e15cfbc`** ✅
  - **Terraform**: `aws_s3_bucket.plex_recommendations_data` (orphaned-resources.tf)
  - **Purpose**: Plex data storage (duplicate?)
  - **Status**: ✅ **ACTIVE** - Has content (plex-data/, plex-recommendations/)
  - **Issue**: ⚠️ Two Plex data buckets - need to verify which is actually used

### Infrastructure/Operations
- **`robert-consulting-terraform-state`** ✅
  - **Terraform**: `aws_s3_bucket.terraform_state`
  - **Purpose**: Terraform state storage
  - **Status**: ✅ **ACTIVE** - Critical infrastructure

- **`robert-consulting-synthetics-results`** ✅
  - **Terraform**: `aws_s3_bucket.synthetics_results`
  - **Purpose**: CloudWatch Synthetics test results
  - **Status**: ✅ **ACTIVE** - In use

- **`robert-consulting-cache`** ✅
  - **Terraform**: `aws_s3_bucket.cache`
  - **Purpose**: Caching and temporary storage
  - **Status**: ✅ **ACTIVE** - Has content (terraform-stats.json)

- **`robert-consulting-terraform-test-1761410906`** ✅
  - **Terraform**: `aws_s3_bucket.terraform_test`
  - **Purpose**: Terraform testing and validation
  - **Status**: ⚠️ **EMPTY** - Test bucket, may not be needed

### Bailey Lessons (Client)
- **`baileylessons-admin-ce4315`** ✅
  - **Terraform**: `module.baileylessons.aws_s3_bucket.admin`
  - **Purpose**: Bailey Lessons admin site
  - **Status**: ⚠️ **DELETED** - Image shows it was deleted, but still in Terraform state

## Buckets NOT in Terraform State ❌

- **`robert-consulting-cloudfront-logs`** ❌
  - **Terraform**: Not managed
  - **Purpose**: CloudFront access logs
  - **Status**: ✅ **ACTIVE** - Has content (access-logs/)
  - **Action**: Should be imported or removed if not needed

- **`robertconsulting-costs`** ❌
  - **Terraform**: Not managed
  - **Purpose**: Cost reports/data
  - **Status**: ✅ **ACTIVE** - Has content (reports/, test object)
  - **Action**: Should be imported or removed if not needed

## Summary

### ✅ In Terraform State (13 buckets)
- 10 actively used buckets
- 1 empty test bucket (may not be needed)
- 1 deleted bucket (baileylessons-admin - needs cleanup)
- 1 duplicate definition (plex.robertconsulting.net in both orphaned and module)

### ❌ Not in Terraform State (2 buckets)
- `robert-consulting-cloudfront-logs` - Has content, should be managed
- `robertconsulting-costs` - Has content, should be managed

### ⚠️ Issues to Address
1. **Duplicate Plex buckets**: Two Plex data buckets - verify which is actually used
2. **Duplicate plex.robertconsulting.net**: Defined in both orphaned-resources.tf and module
3. **Deleted baileylessons bucket**: Still in Terraform state but deleted in AWS
4. **Unmanaged buckets**: Two buckets with content not in Terraform state

## Recommendations

1. **Consolidate Plex buckets**: Determine which Plex data bucket is actually used
2. **Remove duplicate definitions**: Consolidate plex.robertconsulting.net to one location
3. **Clean up deleted bucket**: Remove baileylessons-admin from Terraform state
4. **Import or remove unmanaged buckets**: Decide on cloudfront-logs and costs buckets
5. **Review test bucket**: Consider removing terraform-test if not needed


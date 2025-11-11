# S3 Bucket Status Summary

## ✅ **In Terraform State & Actively Used** (10 buckets)

### Production
1. **`robert-consulting-website`** ✅
   - **Terraform**: `aws_s3_bucket.website_bucket`
   - **Purpose**: Main production website
   - **Status**: Active

2. **`rc-admin-site-1aaef0`** ✅
   - **Terraform**: `aws_s3_bucket.admin`
   - **Purpose**: Admin site (Clients Admin Hub)
   - **Status**: Active

### Staging
3. **`robert-consulting-staging-website`** ✅
   - **Terraform**: `aws_s3_bucket.staging_website_bucket`
   - **Purpose**: Staging website
   - **Status**: Active

4. **`robert-consulting-staging-access-logs`** ✅
   - **Terraform**: `aws_s3_bucket.staging_access_logs`
   - **Purpose**: Staging CloudFront logs
   - **Status**: Active (has content)

### Plex Recommendations
5. **`plex.robertconsulting.net`** ✅
   - **Terraform**: `aws_s3_bucket.plex_domain` (orphaned) AND `module.plex_recommendations.aws_s3_bucket.plex_domain`
   - **Purpose**: Plex domain hosting
   - **Status**: Active (has content)
   - **⚠️ Issue**: Defined in TWO places - duplicate

6. **`plex-recommendations-c7c49ce4`** ✅
   - **Terraform**: `module.plex_recommendations.aws_s3_bucket.plex_data`
   - **Purpose**: Plex data storage (ACTIVELY USED by Lambda)
   - **Status**: Active (34 objects)
   - **Used by**: Lambda function `plex-analyzer` (S3_BUCKET env var)

### Infrastructure
7. **`robert-consulting-terraform-state`** ✅
   - **Terraform**: `aws_s3_bucket.terraform_state`
   - **Purpose**: Terraform state storage
   - **Status**: Critical infrastructure

8. **`robert-consulting-synthetics-results`** ✅
   - **Terraform**: `aws_s3_bucket.synthetics_results`
   - **Purpose**: CloudWatch Synthetics results
   - **Status**: Active

9. **`robert-consulting-cache`** ✅
   - **Terraform**: `aws_s3_bucket.cache`
   - **Purpose**: Caching/temporary storage
   - **Status**: Active (has content: terraform-stats.json)

### Client (Bailey Lessons)
10. **`baileylessons-admin-ce4315`** ⚠️
    - **Terraform**: `module.baileylessons.aws_s3_bucket.admin`
    - **Purpose**: Bailey Lessons admin site
    - **Status**: ❌ **DELETED** (image shows deletion success)
    - **Action**: Remove from Terraform state

## ⚠️ **In Terraform State But Empty/Unused** (1 bucket)

11. **`robert-consulting-terraform-test-1761410906`** ⚠️
    - **Terraform**: `aws_s3_bucket.terraform_test`
    - **Purpose**: Terraform testing
    - **Status**: Empty
    - **Action**: Consider removing if not needed

## ❌ **In Terraform State But Likely Unused** (1 bucket)

12. **`plex-recommendations-data-1e15cfbc`** ❌
    - **Terraform**: `aws_s3_bucket.plex_recommendations_data` (orphaned-resources.tf)
    - **Purpose**: Plex data storage (DUPLICATE)
    - **Status**: Empty (0 objects)
    - **Action**: Remove - Lambda uses `plex-recommendations-c7c49ce4` instead

## ❌ **NOT in Terraform State** (2 buckets)

13. **`robert-consulting-cloudfront-logs`** ❌
    - **Terraform**: Not managed
    - **Purpose**: CloudFront access logs
    - **Status**: Active (has content: access-logs/)
    - **Action**: Import to Terraform or remove if not needed

14. **`robertconsulting-costs`** ❌
    - **Terraform**: Not managed
    - **Purpose**: Cost reports/data
    - **Status**: Active (has content: reports/, test object)
    - **Action**: Import to Terraform or remove if not needed

## Summary

| Category | Count | Action |
|----------|-------|--------|
| ✅ Active & Managed | 10 | Keep |
| ⚠️ Empty/Test | 1 | Review/Remove |
| ❌ Unused/Duplicate | 1 | Remove |
| ❌ Deleted | 1 | Remove from state |
| ❌ Unmanaged | 2 | Import or remove |

## Recommended Actions

1. **Remove deleted bucket from state**: `baileylessons-admin-ce4315`
2. **Remove empty duplicate**: `plex-recommendations-data-1e15cfbc` (Lambda uses the other one)
3. **Consolidate duplicate**: `plex.robertconsulting.net` (remove from one location)
4. **Review test bucket**: `robert-consulting-terraform-test-1761410906` (remove if not needed)
5. **Import or remove unmanaged**: `robert-consulting-cloudfront-logs` and `robertconsulting-costs`


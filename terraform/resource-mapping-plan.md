# Resource Mapping Plan for Module Migration

## 📊 Current State Analysis

**Total Resources Managed:** 16 resources
**Backup Created:** terraform.tfstate.backup-20251025-112151

## 🏗️ Resource Categorization

### Main Site Resources (3 resources)
- `aws_cloudfront_distribution.website` → **main-site module**
- `aws_s3_bucket.website_bucket` → **main-site module**  
- `aws_lambda_function.contact_form` → **main-site module**

### Admin/Staging Resources (5 resources)
- `aws_cloudfront_distribution.admin` → **main-site module** (admin functionality)
- `aws_cloudfront_distribution.staging_website` → **main-site module** (staging environment)
- `aws_s3_bucket.staging_website_bucket` → **main-site module** (staging bucket)
- `aws_s3_bucket.staging_access_logs` → **main-site module** (staging logs)
- `aws_sns_topic.staging_alerts` → **main-site module** (staging notifications)

### Monitoring/Analytics Resources (3 resources)
- `aws_lambda_function.dashboard_api` → **monitoring module**
- `aws_lambda_function.stats_refresher` → **monitoring module**
- `aws_s3_bucket.synthetics_results` → **monitoring module**

### Data Sources (5 resources)
- `data.archive_file.admin_auth_zip` → **main-site module** (admin auth package)
- `data.archive_file.dashboard_api_zip` → **monitoring module** (dashboard package)
- `data.archive_file.stats_refresher_zip` → **monitoring module** (stats package)
- `data.aws_caller_identity.current` → **shared module** (account info)
- `data.aws_region.current` → **shared module** (region info)

## 🎯 Module Assignment Strategy

### main-site module (8 resources)
- All website-related resources
- Admin functionality
- Staging environment
- Contact form functionality

### monitoring module (3 resources)
- Dashboard API
- Stats refresher
- Synthetics results

### shared module (2 resources)
- AWS account/region data sources
- Common utilities

## 📋 Migration Plan

### Phase 1: Preparation ✅
- [x] Create module structure
- [x] Backup current state
- [x] Document resources

### Phase 2: Module Development (SAFE)
- [ ] Complete module configurations
- [ ] Add all required resources to modules
- [ ] Test module structure

### Phase 3: Gradual Migration (CAREFUL)
- [ ] Import resources one by one
- [ ] Validate each import
- [ ] Test functionality

### Phase 4: Cleanup
- [ ] Remove old resource definitions
- [ ] Update references
- [ ] Final validation

## 🛡️ Safety Measures

- **No production changes** until Phase 3
- **Backup created** before any changes
- **Gradual migration** - one resource at a time
- **Validation** at each step
- **Rollback plan** available

## 📊 Expected Benefits

- **Better organization** - resources grouped by purpose
- **Easier maintenance** - clear module boundaries
- **Reusability** - modules can be used for other projects
- **Scalability** - easier to add new resources
- **Security** - better isolation and access control

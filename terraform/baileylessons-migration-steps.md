# Bailey Lessons Migration Steps

## 🎯 **MIGRATION OVERVIEW**

**Project**: baileylessons.com  
**Status**: Phase 3 - Gradual Migration  
**Approach**: One resource at a time, validate each step

## 📋 **RESOURCES TO MIGRATE**

### **From admin-site.tf:**
1. `aws_s3_bucket.admin` - Admin S3 bucket
2. `aws_s3_bucket_public_access_block.admin` - S3 public access block
3. `aws_s3_bucket_versioning.admin` - S3 versioning
4. `random_id.admin_suffix` - Random ID for unique naming
5. `aws_cloudfront_origin_access_control.admin` - CloudFront OAC
6. `aws_s3_bucket_policy.admin` - S3 bucket policy
7. `aws_cloudfront_function.basic_auth` - Basic Auth function
8. `aws_cloudfront_distribution.admin` - CloudFront distribution
9. `aws_route53_record.admin` - Route53 record

### **From main.tf:**
- Module call to `client-infrastructure` (will be replaced by our module)

## 🛡️ **MIGRATION STRATEGY**

### **Step 1: Preparation (SAFE)**
- ✅ Module created and validated
- ✅ Backup created: `terraform.tfstate.backup-20251025-112151`
- ✅ No production changes made yet

### **Step 2: Gradual Import (CAREFUL)**
1. **Import S3 bucket** - Start with least critical resource
2. **Import S3 configurations** - Versioning, encryption, access block
3. **Import CloudFront OAC** - Security configuration
4. **Import CloudFront Function** - Basic Auth
5. **Import CloudFront Distribution** - Main CDN
6. **Import Route53 record** - DNS configuration
7. **Import Random ID** - Unique naming

### **Step 3: Validation (CRITICAL)**
- Validate each import with `terraform plan`
- Test functionality after each step
- Monitor for issues throughout
- Rollback if any problems detected

### **Step 4: Cleanup (FINAL)**
- Remove old configurations from baileylessons repo
- Update references to use module outputs
- Final validation and testing

## 🚨 **SAFETY MEASURES**

### **Before Each Import:**
- Run `terraform plan` to see what will change
- Verify no unexpected changes
- Test current functionality

### **After Each Import:**
- Run `terraform plan` to verify no changes
- Test functionality still works
- Check for any issues

### **Rollback Plan:**
```bash
# If anything goes wrong:
cp terraform.tfstate.backup-20251025-112151 terraform.tfstate
terraform init
terraform plan  # Should show no changes
```

## 📊 **EXPECTED BENEFITS**

### **Security Improvements:**
- Enhanced S3 security with encryption
- CloudFront OAC for secure access
- Basic Auth protection
- TLS 1.2+ enforcement

### **Cost Reductions:**
- PriceClass_100 reduces CloudFront costs
- Minimal resource usage
- Efficient caching

### **Maintainability Gains:**
- Modular structure
- Clear separation of concerns
- Consistent tagging
- Comprehensive documentation

## 🎯 **SUCCESS CRITERIA**

### **Migration Success:**
- All resources successfully imported
- No functionality lost
- Security features working
- Cost optimizations applied

### **Final Validation:**
- `terraform plan` shows no changes
- All functionality working
- Documentation updated
- Old configurations removed

## 🚀 **READY TO BEGIN?**

The migration is ready to begin with:
- ✅ Module validated and tested
- ✅ Backup created
- ✅ Migration plan documented
- ✅ Safety measures in place

**Next step**: Begin with Step 1 - Import S3 bucket (least critical resource)

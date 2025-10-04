# Node.js 18 to 20 Migration Plan

## Overview
This document outlines the migration plan for updating AWS Lambda functions from Node.js 18 (deprecated) to Node.js 20 (LTS).

## Timeline
- **Deadline:** September 1, 2025 (AWS Lambda Node.js 18 end of support)
- **Recommended completion:** By March 2025 (6 months before deadline)

## Affected Resources

### Lambda Functions
- **contact-form-api** (terraform/contact-form-api.tf)
  - Current Runtime: `nodejs18.x`
  - Target Runtime: `nodejs20.x`
  - Purpose: Contact form processing via AWS SES

## Migration Steps

### Phase 1: Preparation (Week 1)
1. **Backup current configuration**
   ```bash
   aws lambda get-function-configuration --function-name contact-form-api > backup-config.json
   ```

2. **Test code compatibility**
   - ✅ Code uses modern ES6+ syntax
   - ✅ AWS SDK v3 compatible
   - ✅ No deprecated Node.js features

3. **Update local development environment**
   - Install Node.js 20 locally
   - Test contact form API locally

### Phase 2: Staging Migration (Week 2)
1. **Update Terraform configuration**
   ```bash
   # Already completed: terraform/contact-form-api.tf
   # Changed: runtime = "nodejs20.x"
   ```

2. **Deploy to staging**
   ```bash
   cd terraform
   terraform plan
   terraform apply
   ```

3. **Test functionality**
   - Test contact form submission
   - Verify email delivery
   - Check CloudWatch logs

### Phase 3: Production Migration (Week 3)
1. **Execute migration script**
   ```bash
   ./terraform/migrate-lambda-runtime.sh
   ```

2. **Verify migration**
   - Check runtime version
   - Test contact form
   - Monitor for 48 hours

3. **Update CI/CD**
   - Update GitHub Actions workflow
   - Update deployment scripts

## Migration Scripts

### Automated Migration
```bash
# Run the migration script
./terraform/migrate-lambda-runtime.sh
```

### Manual Migration (if needed)
```bash
# Update runtime via AWS CLI
aws lambda update-function-configuration \
    --function-name contact-form-api \
    --runtime nodejs20.x \
    --region us-east-1
```

### Rollback (if issues occur)
```bash
# Rollback to Node.js 18 (temporary)
./terraform/rollback-lambda-runtime.sh
```

## Testing Strategy

### Pre-Migration Testing
1. **Local testing**
   - Test with Node.js 20 locally
   - Verify all dependencies work

2. **Staging testing**
   - Deploy to staging environment
   - Test contact form functionality
   - Monitor performance metrics

### Post-Migration Testing
1. **Functional testing**
   - Submit test contact form
   - Verify email delivery
   - Check error handling

2. **Performance monitoring**
   - Monitor CloudWatch metrics
   - Check execution times
   - Monitor error rates

## Risk Assessment

### Low Risk Factors
- ✅ Code is modern and compatible
- ✅ Uses AWS SDK v3 (compatible with Node.js 20)
- ✅ No deprecated Node.js features
- ✅ Simple function with minimal dependencies

### Mitigation Strategies
- **Backup configuration** before migration
- **Test in staging** environment first
- **Monitor closely** for 48 hours post-migration
- **Rollback plan** available if issues occur

## Success Criteria

### Technical Success
- [ ] Runtime updated to `nodejs20.x`
- [ ] Function executes without errors
- [ ] Contact form submissions work
- [ ] Email delivery functions correctly
- [ ] Performance maintained or improved

### Business Success
- [ ] No downtime during migration
- [ ] Contact form remains functional
- [ ] Email notifications continue working
- [ ] No user impact

## Post-Migration Tasks

### Immediate (0-24 hours)
- [ ] Monitor CloudWatch logs
- [ ] Test contact form functionality
- [ ] Verify email delivery
- [ ] Check performance metrics

### Short-term (1-7 days)
- [ ] Update documentation
- [ ] Update CI/CD pipelines
- [ ] Update GitHub Actions workflow
- [ ] Remove rollback scripts (after 1 week)

### Long-term (1-4 weeks)
- [ ] Consider Node.js 22 migration planning
- [ ] Update development environment documentation
- [ ] Review other AWS services for similar updates

## Monitoring and Alerts

### CloudWatch Metrics to Monitor
- **Duration:** Function execution time
- **Errors:** Error rate and types
- **Invocations:** Function call frequency
- **Throttles:** Function throttling events

### Alert Thresholds
- Error rate > 1%
- Duration increase > 50%
- Throttle events > 0

## Documentation Updates

### Files to Update
- [ ] README.md (if runtime mentioned)
- [ ] Deployment guides
- [ ] CI/CD documentation
- [ ] Developer setup instructions

### New Files Created
- [x] NODEJS_MIGRATION_PLAN.md (this file)
- [x] migrate-lambda-runtime.sh
- [x] rollback-lambda-runtime.sh

## Contact and Support

### AWS Support
- **Documentation:** [AWS Lambda Runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
- **Migration Guide:** [AWS Lambda Node.js Migration](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-nodejs.html)

### Internal Support
- **Primary Contact:** Development Team
- **Backup Contact:** DevOps Team
- **Emergency Contact:** System Administrator

---

**Last Updated:** $(date)
**Next Review:** 3 months after migration completion

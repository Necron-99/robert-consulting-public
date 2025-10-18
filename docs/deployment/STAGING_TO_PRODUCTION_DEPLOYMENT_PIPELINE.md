# Staging to Production Deployment Pipeline

## Overview

This document describes the comprehensive staging-to-production deployment pipeline that ensures all changes are thoroughly tested before reaching production.

## Pipeline Architecture

```
Commit to main → Staging Deployment → Comprehensive Testing → Manual Approval → Production Deployment → Monitoring
```

## Workflow Stages

### Stage 1: Staging Deployment 🧪
- **Trigger**: Every commit to `main` branch
- **Action**: Automatic deployment to staging environment
- **Location**: `https://staging.robertconsulting.net`
- **Features**:
  - IP-restricted access (WAF protection)
  - Identical infrastructure to production
  - Security headers and CloudFront configuration
  - Content sync with exclusions for non-production files

### Stage 2: Comprehensive Testing 🧪
- **Trigger**: After successful staging deployment
- **Duration**: ~5-10 minutes
- **Tests Include**:

#### 2.1 Basic Functionality Tests
- HTTP status validation (200 OK)
- HTML structure validation
- Page accessibility checks
- Content presence verification

#### 2.2 Security Headers Validation
- `X-Frame-Options: DENY`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy` presence
- `Strict-Transport-Security` validation
- `X-Content-Type-Options` verification

#### 2.3 Content Integrity Tests
- Broken link detection
- Missing image validation
- Meta tag verification
- Empty attribute checks

#### 2.4 Responsive Design Tests
- Multiple user agent testing
- Viewport meta tag validation
- Mobile compatibility checks

#### 2.5 Performance Tests
- Page load time validation (< 10 seconds)
- File size optimization checks
- CDN performance verification

#### 2.6 Security Scan (Basic)
- Hardcoded secret detection
- Mixed content identification
- CSP policy validation

### Stage 3: Manual Approval Gate 👥
- **Trigger**: After all tests pass
- **Requirement**: Human approval required
- **Environment**: `production-deployment` (GitHub environment)
- **Review Process**:
  - Review staging environment
  - Validate test results
  - Approve or reject deployment
  - Emergency bypass available (not recommended)

### Stage 4: Production Deployment 🚀
- **Trigger**: After manual approval
- **Action**: Deploy to production environment
- **Location**: `https://robertconsulting.net`
- **Features**:
  - CloudFront invalidation
  - Content validation
  - Security header verification
  - Performance monitoring

### Stage 5: Post-deployment Monitoring 📊
- **Trigger**: After production deployment
- **Duration**: ~2-3 minutes
- **Monitoring**:
  - Site accessibility verification
  - Performance metrics collection
  - Health check validation
  - CloudWatch metrics review

## Workflow Files

### Primary Workflow
- **File**: `.github/workflows/staging-to-production-deployment.yml`
- **Purpose**: Main deployment pipeline
- **Triggers**: Push to main, manual dispatch

### Emergency Workflow
- **File**: `.github/workflows/deploy.yml` (Legacy)
- **Purpose**: Emergency deployments only
- **Triggers**: Manual dispatch only
- **Warning**: Bypasses all safety checks

### Environment Configuration
- **File**: `.github/environments/production-deployment.md`
- **Purpose**: Manual approval configuration
- **Access**: Repository administrators only

## Usage Instructions

### Normal Deployment Process

1. **Make Changes**: Commit changes to `main` branch
2. **Automatic Staging**: Pipeline automatically deploys to staging
3. **Review Staging**: Visit `https://staging.robertconsulting.net`
4. **Wait for Tests**: Comprehensive test battery runs automatically
5. **Manual Approval**: Approve deployment in GitHub Actions
6. **Production Deploy**: Automatic production deployment after approval
7. **Monitor**: Post-deployment monitoring and validation

### Emergency Deployment Process

1. **Go to Actions**: Navigate to GitHub Actions
2. **Select Emergency Workflow**: Choose "Legacy Direct Deployment"
3. **Run Workflow**: Click "Run workflow"
4. **Confirm Emergency**: Set `emergency_deployment: true`
5. **Deploy**: Workflow bypasses all safety checks
6. **Monitor Closely**: Watch production for issues

### Manual Workflow Dispatch

```yaml
# Normal deployment with tests
workflow_dispatch:
  skip_tests: false
  force_production: false

# Skip tests (not recommended)
workflow_dispatch:
  skip_tests: true
  force_production: false

# Force production (emergency only)
workflow_dispatch:
  skip_tests: false
  force_production: true
```

## Security Features

### Staging Environment Security
- **WAF Protection**: IP-based access control
- **Rate Limiting**: 2000 requests per 5 minutes
- **Suspicious User Agent Blocking**: Blocks malicious tools
- **Security Headers**: Identical to production

### Production Environment Security
- **CloudFront Security**: All production security features
- **WAF Protection**: Rate limiting and threat blocking
- **Security Headers**: Comprehensive security policy
- **Monitoring**: Real-time security monitoring

## Monitoring and Alerts

### CloudWatch Integration
- **Performance Metrics**: Response times, error rates
- **Security Metrics**: WAF blocks, suspicious activity
- **Cost Monitoring**: Resource usage tracking
- **Availability Monitoring**: Uptime and health checks

### GitHub Actions Integration
- **Deployment Logs**: Complete audit trail
- **Test Results**: Detailed test reporting
- **Approval History**: Manual approval tracking
- **Rollback Capability**: Emergency rollback procedures

## Troubleshooting

### Common Issues

#### Staging Deployment Fails
- **Check**: AWS credentials and permissions
- **Verify**: S3 bucket accessibility
- **Review**: CloudFront distribution status

#### Tests Fail
- **Review**: Test output in GitHub Actions
- **Check**: Staging site accessibility
- **Validate**: Security header configuration

#### Manual Approval Not Available
- **Verify**: GitHub environment configuration
- **Check**: Repository permissions
- **Contact**: Repository administrator

#### Production Deployment Fails
- **Check**: Manual approval status
- **Verify**: AWS credentials
- **Review**: CloudFront invalidation status

### Emergency Procedures

#### Rollback Process
1. **Identify**: Previous working commit
2. **Emergency Deploy**: Use emergency workflow
3. **Monitor**: Watch for stability
4. **Investigate**: Root cause analysis

#### Bypass Safety Checks
1. **Emergency Only**: Use `force_production: true`
2. **Document**: Reason for bypass
3. **Monitor**: Extra vigilance required
4. **Review**: Post-deployment analysis

## Best Practices

### Development Workflow
1. **Feature Branches**: Develop in feature branches
2. **Pull Requests**: Use PRs for code review
3. **Merge to Main**: Only merge tested code
4. **Monitor Pipeline**: Watch deployment progress

### Testing Strategy
1. **Local Testing**: Test changes locally first
2. **Staging Validation**: Always review staging
3. **Test Results**: Review all test outputs
4. **Performance**: Monitor performance impact

### Security Practices
1. **No Secrets**: Never commit secrets
2. **Security Headers**: Maintain security configuration
3. **Access Control**: Limit staging access
4. **Monitoring**: Watch security metrics

## Cost Optimization

### Staging Environment Costs
- **S3 Storage**: ~$0.50/month
- **CloudFront**: ~$1.00/month
- **WAF**: ~$1.00/month
- **Route53**: ~$0.50/month
- **Total**: ~$3.00/month

### Production Environment Costs
- **S3 Storage**: ~$1.00/month
- **CloudFront**: ~$5.00/month
- **WAF**: ~$5.00/month
- **Route53**: ~$0.50/month
- **Total**: ~$11.50/month

## Future Enhancements

### Planned Improvements
- **Automated Rollback**: Automatic rollback on failure
- **Performance Testing**: Load testing integration
- **Security Scanning**: OWASP ZAP integration
- **Blue-Green Deployment**: Zero-downtime deployments

### Monitoring Enhancements
- **Real-time Alerts**: Slack/email notifications
- **Performance Dashboards**: Enhanced monitoring
- **Cost Alerts**: Budget monitoring
- **Security Alerts**: Threat detection

## Support and Maintenance

### Regular Maintenance
- **Weekly**: Review deployment logs
- **Monthly**: Update security configurations
- **Quarterly**: Review and optimize costs
- **Annually**: Security audit and review

### Documentation Updates
- **Keep Current**: Update this document with changes
- **Version Control**: Track documentation changes
- **Team Training**: Ensure team understands process
- **Emergency Procedures**: Regular emergency drill practice

---

**Last Updated**: October 2025  
**Version**: 1.0  
**Maintainer**: Robert Consulting Development Team

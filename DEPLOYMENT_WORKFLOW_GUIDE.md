# Production Deployment Workflow Guide

## 🎯 **Overview**

This guide explains the new production deployment workflow with manual approval and IP address restrictions for enhanced security.

## 🔄 **Deployment Workflows**

### **1. Staging Deployment (Automatic)**
- **File**: `.github/workflows/deploy.yml`
- **Trigger**: Push to `main` branch or manual dispatch
- **Purpose**: Automatic deployment to staging environment
- **Security**: IP address verification required
- **Approval**: Not required (automatic)

### **2. Production Deployment (Manual Approval)**
- **File**: `.github/workflows/production-deploy.yml`
- **Trigger**: Manual dispatch only
- **Purpose**: Production deployment with full security checks
- **Security**: IP address verification + comprehensive security scanning
- **Approval**: Manual approval required

## 🔒 **Security Features**

### **IP Address Restrictions**
- **Staging**: IP verification for all deployments
- **Production**: IP verification + manual approval
- **Configuration**: Set `ALLOWED_IP_ADDRESS` in GitHub Secrets
- **Verification**: Automatic IP check using `api.ipify.org`

### **Security Scanning**
- **Dependency Audit**: npm audit for vulnerabilities
- **Secret Detection**: Scan for passwords, keys, tokens
- **HTTP Link Check**: Ensure HTTPS usage
- **Vulnerability Classification**: Critical, High, Medium, Low
- **Security Gates**: Block deployment on critical issues

### **Manual Approval Process**
- **Production Only**: Manual approval required for production
- **Security Review**: Review security scan results
- **Force Override**: Option to force deploy despite issues
- **Skip Security**: Option to skip security scanning (not recommended)

## 🚀 **Deployment Process**

### **Staging Deployment (Automatic)**
```yaml
# Triggered on push to main branch
1. IP Address Verification
2. AWS Credentials Setup
3. Security Scanning (optional skip)
4. Version Information Generation
5. S3 Deployment
6. CloudFront Cache Invalidation
7. Deployment Verification
```

### **Production Deployment (Manual)**
```yaml
# Manual trigger required
1. IP Address Verification
2. Pre-deployment Security Checks
3. Manual Approval Required
4. Production Environment Deployment
5. CloudFront Cache Invalidation
6. GitHub Release Creation
7. Deployment Verification
```

## 📋 **Required GitHub Secrets**

### **AWS Credentials**
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### **Security Configuration**
- `ALLOWED_IP_ADDRESS`: Your external IP address for deployment authorization

### **Environment Variables**
- `PRODUCTION_BUCKET`: robert-consulting-website
- `CLOUDFRONT_DISTRIBUTION_ID`: E3HUVB85SPZFHO

## 🛡️ **Security Gates**

### **Critical Issues (Block Deployment)**
- **Critical Vulnerabilities**: Any critical vulnerabilities block deployment
- **Secrets in Code**: Any secrets found block deployment
- **IP Address Mismatch**: Wrong IP address blocks deployment

### **High Issues (Warning)**
- **High Vulnerabilities**: More than 5 high vulnerabilities block deployment
- **Medium/Low Issues**: Warnings but don't block deployment

### **Force Override Options**
- **Force Deploy**: Override security gates (not recommended)
- **Skip Security**: Skip security scanning (not recommended)

## 🔧 **Manual Approval Process**

### **Step 1: Trigger Production Deployment**
1. Go to GitHub Actions
2. Select "Production Deployment with Manual Approval"
3. Click "Run workflow"
4. Set `deploy_to_production` to `true`
5. Review other options
6. Click "Run workflow"

### **Step 2: Review Security Results**
- **Security Status**: Overall security status
- **Dependencies**: Dependency vulnerability status
- **Vulnerabilities**: Count by severity level
- **Secrets Found**: Number of secrets detected
- **CDN Issues**: HTTP link issues found

### **Step 3: Approve or Reject**
- **Approve**: If security results are acceptable
- **Reject**: If security issues need to be fixed first
- **Force Deploy**: Override security gates (risky)

## 📊 **Deployment Monitoring**

### **Staging Deployment**
- **Automatic**: Deploys on every push to main
- **IP Restricted**: Only from authorized IP address
- **Quick Feedback**: Fast deployment for testing

### **Production Deployment**
- **Manual Approval**: Requires explicit approval
- **Security Scanned**: Comprehensive security checks
- **Release Created**: GitHub release with deployment info
- **Verified**: Post-deployment verification

## 🚨 **Security Best Practices**

### **IP Address Management**
- **Static IP**: Use a static IP address for deployments
- **VPN Access**: Consider VPN for additional security
- **Regular Updates**: Update IP address if it changes

### **Security Scanning**
- **Regular Scans**: Run security scans before production
- **Fix Issues**: Address security issues promptly
- **No Secrets**: Never commit secrets to repository

### **Deployment Approval**
- **Review Results**: Always review security scan results
- **Team Approval**: Consider team approval for production
- **Documentation**: Document deployment decisions

## 🔍 **Troubleshooting**

### **IP Address Issues**
```bash
# Check your current IP
curl -s https://api.ipify.org

# Update GitHub Secret
# Go to Settings > Secrets > ALLOWED_IP_ADDRESS
```

### **Security Scan Failures**
```bash
# Check for secrets
grep -r -i "password\|secret\|key\|token" website/

# Check for HTTP links
grep -r "http://" website/

# Run npm audit
npm audit
```

### **Deployment Failures**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check S3 bucket access
aws s3 ls s3://robert-consulting-website

# Check CloudFront distribution
aws cloudfront get-distribution --id E3HUVB85SPZFHO
```

## 📈 **Monitoring and Alerts**

### **Deployment Notifications**
- **GitHub Actions**: Email notifications on success/failure
- **GitHub Releases**: Automatic release creation
- **Security Alerts**: Security scan result notifications

### **Production Monitoring**
- **CloudWatch**: AWS service monitoring
- **Status Page**: Public status monitoring
- **Cost Alerts**: Budget and cost monitoring

## 🎯 **Benefits**

### **Enhanced Security**
- **IP Restrictions**: Only authorized IPs can deploy
- **Security Scanning**: Comprehensive vulnerability detection
- **Manual Approval**: Human oversight for production

### **Controlled Deployments**
- **Staging First**: Automatic staging for testing
- **Production Control**: Manual approval for production
- **Rollback Capability**: Easy rollback if issues occur

### **Compliance and Auditing**
- **Deployment Logs**: Complete deployment history
- **Security Reports**: Detailed security scan results
- **Approval Tracking**: Who approved what and when

## 🚀 **Next Steps**

1. **Set up GitHub Secrets**: Configure `ALLOWED_IP_ADDRESS`
2. **Test Staging Deployment**: Verify staging workflow
3. **Configure Production Environment**: Set up production environment
4. **Train Team**: Educate team on new deployment process
5. **Monitor Deployments**: Set up monitoring and alerting

**🎯 Your deployment workflow now includes manual approval for production deployments and IP address restrictions for enhanced security!** 🛡️✅

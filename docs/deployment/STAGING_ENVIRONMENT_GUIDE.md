# Staging Environment Guide

## 🎯 Overview

The staging environment is a **production-mirror** setup that provides identical infrastructure to production but with restricted access and cost optimizations. This allows for safe testing of security remediation and changes before deploying to production.

## 🏗️ Infrastructure Components

### **Identical to Production:**
- ✅ **S3 Bucket**: `robert-consulting-staging-website`
- ✅ **CloudFront Distribution**: With all security headers
- ✅ **Custom Domain**: `staging.robertconsulting.net`
- ✅ **SSL Certificate**: ACM-managed SSL/TLS
- ✅ **WAF Protection**: AWS WAF with security rules
- ✅ **CloudWatch Monitoring**: Error rate monitoring
- ✅ **Security Headers**: All production security headers

### **Staging-Specific Features:**
- 🔒 **IP-Based Access Control**: Restricted to allowed IP addresses
- 💰 **Cost Optimized**: PriceClass_100 (US, Canada, Europe only)
- 📊 **Minimal Monitoring**: Only essential alarms
- 🛡️ **Same Security Posture**: Identical security configuration

## 🚀 Deployment Process

### **1. Deploy Staging Infrastructure**

```bash
# Run the deployment script
./scripts/deploy-staging-environment.sh
```

This creates:
- S3 bucket with website hosting
- CloudFront distribution with security headers
- SSL certificate and DNS validation
- WAF with IP restrictions
- CloudWatch monitoring

### **2. Configure IP Access**

Edit `terraform/staging-environment.tf`:

```hcl
variable "staging_allowed_ips" {
  description = "List of IP addresses allowed to access staging environment"
  type        = list(string)
  default     = [
    "1.2.3.4/32",  # Your home IP
    "5.6.7.8/32",  # Your office IP
    # Add more IPs as needed
  ]
}
```

Then apply the changes:

```bash
cd terraform
terraform apply
```

### **3. Deploy Website Content**

```bash
# Deploy website content to staging
aws s3 sync website/ s3://robert-consulting-staging-website --delete

# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw staging_cloudfront_distribution_id) \
  --paths "/*"
```

## 🔍 Security Testing Workflow

### **Recommended Process:**

1. **🔧 Make Security Changes**
   - Update Terraform configurations
   - Modify security headers
   - Adjust WAF rules

2. **🧪 Test on Staging**
   - Deploy changes to staging
   - Run ZAP staging scan
   - Validate security improvements

3. **🚀 Deploy to Production**
   - Apply changes to production
   - Run ZAP production scan
   - Verify production security

### **ZAP Scanning:**

#### **Staging Scan:**
```bash
# Via GitHub Actions
Actions → OWASP ZAP Staging Security Scan → Run workflow
```

#### **Production Scan:**
```bash
# Via GitHub Actions
Actions → OWASP ZAP Production Security Scan → Run workflow
```

## 📊 Expected Results Comparison

### **Staging Environment (With Security Headers):**
```
✅ X-Frame-Options: DENY
✅ X-Content-Type-Options: nosniff
✅ Content-Security-Policy: comprehensive policy
✅ Strict-Transport-Security: max-age=31536000
✅ Cross-Origin policies configured
✅ Permissions-Policy: browser restrictions
✅ Server header: CloudFront (not sensitive)
```

### **Production Environment (Identical):**
```
✅ X-Frame-Options: DENY
✅ X-Content-Type-Options: nosniff
✅ Content-Security-Policy: comprehensive policy
✅ Strict-Transport-Security: max-age=31536000
✅ Cross-Origin policies configured
✅ Permissions-Policy: browser restrictions
✅ Server header: CloudFront (not sensitive)
```

## 💰 Cost Analysis

### **Monthly Costs (Estimated):**

| Component | Production | Staging | Savings |
|-----------|------------|---------|---------|
| S3 Storage | ~$1 | ~$1 | $0 |
| CloudFront | ~$5 | ~$3 | $2 |
| WAF | ~$5 | ~$5 | $0 |
| Route53 | ~$1 | $0 | $1 |
| SSL Certificate | $0 | $0 | $0 |
| CloudWatch | ~$2 | ~$1 | $1 |
| **Total** | **~$14** | **~$10** | **~$4** |

### **Cost Optimizations:**
- **PriceClass_100**: Only US, Canada, Europe (vs global)
- **Minimal Monitoring**: Only error rate alarm
- **Shared Route53 Zone**: No additional hosted zone
- **Same SSL Certificate**: Reuses existing certificate

## 🛡️ Security Features

### **Access Control:**
- **IP Whitelist**: Only allowed IPs can access staging
- **WAF Protection**: Rate limiting and suspicious user agent blocking
- **HTTPS Only**: All traffic encrypted

### **Security Headers (Identical to Production):**
- **Content-Security-Policy**: Comprehensive CSP
- **X-Frame-Options**: DENY
- **X-Content-Type-Options**: nosniff
- **Strict-Transport-Security**: HSTS with preload
- **Cross-Origin Policies**: CORP, COOP, CORS
- **Permissions-Policy**: Browser feature restrictions

### **Monitoring:**
- **Error Rate Alarm**: CloudWatch alarm for 4xx errors
- **SNS Notifications**: Alert on high error rates
- **WAF Metrics**: CloudWatch metrics for security events

## 🔧 Management Commands

### **Deploy to Staging:**
```bash
# Deploy website content
aws s3 sync website/ s3://robert-consulting-staging-website --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(cd terraform && terraform output -raw staging_cloudfront_distribution_id) \
  --paths "/*"
```

### **Update IP Restrictions:**
```bash
cd terraform
# Edit staging_allowed_ips variable
terraform apply
```

### **Check Staging Status:**
```bash
# Test staging site
curl -I https://staging.robertconsulting.net

# Check CloudFront distribution
aws cloudfront get-distribution --id $(cd terraform && terraform output -raw staging_cloudfront_distribution_id)
```

## 🚨 Troubleshooting

### **Common Issues:**

#### **1. Access Denied (403)**
- **Cause**: IP not in allowed list
- **Fix**: Add your IP to `staging_allowed_ips` variable

#### **2. SSL Certificate Issues**
- **Cause**: DNS validation not complete
- **Fix**: Check Route53 records and wait for validation

#### **3. CloudFront Not Updating**
- **Cause**: Cache not invalidated
- **Fix**: Create CloudFront invalidation

#### **4. WAF Blocking Requests**
- **Cause**: Rate limiting or suspicious user agent
- **Fix**: Check WAF logs and adjust rules if needed

## 📈 Benefits

### **Security Benefits:**
- **Safe Testing**: Test security changes without affecting production
- **Identical Environment**: Same security posture as production
- **Restricted Access**: Only authorized users can access staging
- **Comprehensive Testing**: Full security header validation

### **Operational Benefits:**
- **Cost Effective**: Minimal additional costs
- **Easy Management**: Simple deployment and updates
- **Automated Testing**: Integrated with CI/CD pipeline
- **Quick Feedback**: Fast validation of security changes

### **Development Benefits:**
- **Risk Mitigation**: Prevent security regressions
- **Confidence**: Validate changes before production
- **Iterative Improvement**: Safe environment for experimentation
- **Documentation**: Clear process for security testing

This staging environment provides the perfect balance of security, cost-effectiveness, and functionality for testing security remediation before production deployment.

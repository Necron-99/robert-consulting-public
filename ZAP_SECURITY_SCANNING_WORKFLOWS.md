# OWASP ZAP Security Scanning Workflows

This repository includes two separate OWASP ZAP security scanning workflows designed for different purposes in the development lifecycle.

## 🔒 Production Security Scan

**Workflow**: `OWASP ZAP Production Security Scan`  
**File**: `.github/workflows/owasp-zap-security-scan.yml`

### Purpose
- Validates the **production site** security posture with CloudFront security headers
- Scans `https://robertconsulting.net` (production CloudFront distribution)
- Includes comprehensive security headers implemented via CloudFront Response Headers Policy

### Triggers
- **Automatic**: On push to `main` branch (website/admin changes)
- **Scheduled**: Daily at 2 AM UTC
- **Manual**: Via GitHub Actions UI with options for production/staging

### Security Headers Tested
- ✅ Content-Security-Policy
- ✅ X-Frame-Options: DENY
- ✅ X-Content-Type-Options: nosniff
- ✅ Strict-Transport-Security
- ✅ Cross-Origin policies
- ✅ Permissions-Policy
- ✅ Server header removal

### Features
- **Issue Creation**: Automatically creates GitHub issues for security findings
- **Issue Closure**: Automatically closes resolved issues
- **SARIF Upload**: Uploads results to GitHub Security tab
- **Comprehensive Reporting**: HTML, JSON, XML reports

---

## 🧪 Staging Security Scan

**Workflow**: `OWASP ZAP Staging Security Scan`  
**File**: `.github/workflows/owasp-zap-staging-scan.yml`

### Purpose
- Tests security remediation on the **staging site** before production deployment
- Scans `http://robert-consulting-testing-site.s3-website-us-east-1.amazonaws.com` (staging S3 website)
- Validates fixes without security headers (direct S3 endpoint)

### Triggers
- **Automatic**: On push to `main` branch (website/admin changes)
- **Manual**: Via GitHub Actions UI

### Use Cases
1. **Pre-deployment Testing**: Test security fixes before deploying to production
2. **Development Validation**: Verify changes work on staging environment
3. **Baseline Comparison**: Compare staging vs production security posture

### Features
- **Simple Reporting**: HTML, JSON, XML reports (no issue creation)
- **Fast Feedback**: Quick validation of security changes
- **Development Focus**: Designed for iterative security improvements

---

## 🔄 Recommended Workflow

### For Security Remediation:

1. **Make Security Changes** (e.g., update Terraform, add headers)
2. **Run Staging Scan** → Validate changes work on staging
3. **Deploy to Production** → Apply changes to production
4. **Run Production Scan** → Verify production security posture

### For Regular Monitoring:

- **Production Scan**: Runs automatically daily + on deployments
- **Staging Scan**: Run manually when testing changes

---

## 📊 Expected Results

### Staging Site (No Security Headers)
```
❌ Missing Anti-clickjacking Header
❌ X-Content-Type-Options Header Missing  
❌ Content Security Policy Header Not Set
❌ Server Leaks Version Information
❌ Permissions Policy Header Not Set
```

### Production Site (With CloudFront Security Headers)
```
✅ X-Frame-Options: DENY
✅ X-Content-Type-Options: nosniff
✅ Content-Security-Policy: comprehensive policy
✅ Strict-Transport-Security: max-age=31536000
✅ Cross-Origin policies configured
✅ Permissions-Policy: browser restrictions
✅ Server header: CloudFront (not sensitive)
```

---

## 🛠️ Manual Execution

### Run Production Scan:
```bash
# Via GitHub Actions UI
Actions → OWASP ZAP Production Security Scan → Run workflow
```

### Run Staging Scan:
```bash
# Via GitHub Actions UI  
Actions → OWASP ZAP Staging Security Scan → Run workflow
```

### Run Both Scans:
```bash
# Run staging first to test changes
Actions → OWASP ZAP Staging Security Scan → Run workflow

# Then run production to validate deployment
Actions → OWASP ZAP Production Security Scan → Run workflow
```

---

## 📈 Security Improvement Process

1. **Identify Issue**: Production scan finds security issue
2. **Develop Fix**: Update Terraform/configuration
3. **Test on Staging**: Run staging scan to validate fix
4. **Deploy to Production**: Apply changes via Terraform
5. **Verify Fix**: Run production scan to confirm resolution
6. **Monitor**: Daily production scans ensure ongoing security

This dual-workflow approach ensures security improvements are tested in a safe environment before being deployed to production, following security best practices.

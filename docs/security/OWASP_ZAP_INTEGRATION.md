# OWASP ZAP Security Scanning Integration

## Overview

This repository now includes automated OWASP ZAP (Zed Attack Proxy) security scanning integrated into the GitHub Actions CI/CD pipeline. OWASP ZAP is an open-source web application security scanner that helps identify vulnerabilities in your web applications.

## Features

### ✅ **Automated Security Scanning**
- **Baseline Scan**: Quick security scan on every push to main and pull requests
- **Full Scan**: Comprehensive deep scan scheduled daily at 2 AM UTC
- **API Scan**: Specialized scanning for API endpoints (manual trigger or scheduled)

### ✅ **Multiple Scan Types**
1. **Baseline Scan** - Fast passive scanning for common vulnerabilities
2. **Full Scan** - Active scanning with spider and attack simulation
3. **API Scan** - Specialized scanning for REST APIs

### ✅ **Comprehensive Reporting**
- **HTML Reports**: Human-readable security reports
- **JSON Reports**: Machine-readable data for automation
- **SARIF Reports**: GitHub Security tab integration
- **Workflow Summary**: Quick overview in GitHub Actions

### ✅ **GitHub Security Integration**
- Results automatically uploaded to GitHub Security tab
- View vulnerabilities alongside code
- Track security issues over time
- Integrated with GitHub Advanced Security features

## Workflow Triggers

### Automatic Triggers
1. **Push to Main Branch** (when website or admin files change)
   ```yaml
   paths:
     - 'website/**'
     - 'admin/**'
     - '.github/workflows/owasp-zap-security-scan.yml'
   ```

2. **Pull Requests** (when website or admin files change)
   ```yaml
   paths:
     - 'website/**'
     - 'admin/**'
   ```

3. **Daily Schedule** (2 AM UTC)
   ```yaml
   schedule:
     - cron: '0 2 * * *'
   ```

### Manual Triggers
You can manually trigger scans with custom parameters:

1. Go to **Actions** tab in GitHub
2. Select **OWASP ZAP Security Scan** workflow
3. Click **Run workflow**
4. Configure options:
   - **Target URL**: Custom URL to scan (default: https://robertconsulting.net)
   - **Scan Type**: Choose between baseline, full, or api

## Scan Types Explained

### Baseline Scan (Default)
- **Duration**: 2-5 minutes
- **Aggressiveness**: Passive scanning only
- **Use Case**: Quick security checks, CI/CD integration
- **Detects**: Common vulnerabilities, misconfigurations, missing security headers
- **Best For**: Every commit, pull requests

### Full Scan
- **Duration**: 30-60 minutes
- **Aggressiveness**: Active scanning with attacks
- **Use Case**: Comprehensive security assessment
- **Detects**: All vulnerabilities including complex attack vectors
- **Best For**: Scheduled scans, major releases

### API Scan
- **Duration**: 10-20 minutes
- **Aggressiveness**: API-specific testing
- **Use Case**: REST API endpoint testing
- **Detects**: API-specific vulnerabilities, authentication issues
- **Best For**: API deployments, authentication changes

## Accessing Scan Results

### 1. GitHub Security Tab
- Navigate to **Security** → **Code scanning alerts**
- View all ZAP findings integrated with your code
- Filter by severity: High, Medium, Low, Informational
- Track remediation status

### 2. Workflow Artifacts
- Go to **Actions** → Select the workflow run
- Scroll to **Artifacts** section
- Download `zap-security-reports` (contains HTML, JSON, SARIF files)
- Reports retained for 30 days

### 3. Workflow Summary
- Go to **Actions** → Select the workflow run
- View **Summary** section
- See quick metrics:
  - 🔴 High severity issues
  - 🟡 Medium severity issues
  - 🟠 Low severity issues
  - ℹ️ Informational alerts

## Configuration

### ZAP Rules Configuration
The `.zap/rules.tsv` file allows you to customize ZAP behavior:

```tsv
# Format: Rule ID	Action (IGNORE, INFO, LOW, MEDIUM, HIGH)
10021	HIGH	# XSS Reflected
10020	HIGH	# XSS Stored
10015	HIGH	# SQL Injection
```

**Actions**:
- `HIGH`: Report as high severity
- `MEDIUM`: Report as medium severity
- `LOW`: Report as low severity
- `INFO`: Report as informational
- `IGNORE`: Suppress this rule (false positives)

### Workflow Customization

Edit `.github/workflows/owasp-zap-security-scan.yml` to customize:

**Change scan schedule**:
```yaml
schedule:
  - cron: '0 2 * * *'  # Change time/frequency
```

**Modify scan options**:
```yaml
cmd_options: '-a -j -T 30'  # Add ZAP CLI options
```

**Adjust fail conditions**:
```yaml
fail_action: true  # Fail workflow on high severity findings
```

## Integration with Existing Security

### Complements Current Security Measures
OWASP ZAP adds another layer to your existing security:

1. **Static Analysis** (Pre-production Validation)
   - Code scanning for secrets, credentials
   - Terraform security checks
   - Shell script validation

2. **Dynamic Analysis** (OWASP ZAP) ← **NEW**
   - Runtime vulnerability detection
   - Attack simulation
   - Configuration validation

3. **Infrastructure Security**
   - AWS WAF protection
   - CloudFront security headers
   - IP whitelisting

4. **Monitoring & Alerts**
   - CloudWatch alarms
   - SNS notifications
   - Security metrics dashboard

## Common Vulnerabilities Detected

OWASP ZAP can detect:

### High Severity
- ❗ **SQL Injection**: Database manipulation attacks
- ❗ **Cross-Site Scripting (XSS)**: Code injection vulnerabilities
- ❗ **Path Traversal**: Unauthorized file access
- ❗ **Remote Code Execution**: Server compromise risks
- ❗ **XML External Entity (XXE)**: XML processing vulnerabilities

### Medium Severity
- ⚠️ **Missing Security Headers**: CSP, HSTS, X-Frame-Options
- ⚠️ **Insecure Cookies**: Missing secure/httponly flags
- ⚠️ **Information Disclosure**: Sensitive data exposure
- ⚠️ **CSRF Vulnerabilities**: Cross-site request forgery

### Low Severity
- ⚪ **Directory Browsing**: Exposed directory listings
- ⚪ **Weak SSL/TLS Configuration**: Encryption issues
- ⚪ **Verbose Error Messages**: Information leakage

## Remediation Workflow

When ZAP finds vulnerabilities:

1. **Review findings** in GitHub Security tab
2. **Prioritize by severity**:
   - Fix HIGH severity immediately
   - Schedule MEDIUM for next sprint
   - Document LOW for backlog
3. **Implement fixes** in code
4. **Create pull request** with fixes
5. **Verify** ZAP scan passes on PR
6. **Merge** and deploy

## Performance Impact

### CI/CD Impact
- **Baseline Scan**: Adds 2-5 minutes to deployment pipeline
- **Doesn't block deployments** (fail_action: false by default)
- **Runs on staging** to avoid production impact

### Cost Impact
- **GitHub Actions**: ~$0 (included in free tier for public repos)
- **AWS S3/CloudFront**: Minimal (~$0.01 per scan for data transfer)
- **Total Monthly**: ~$3 for daily scans + PR scans

## Best Practices

### 1. Review Findings Regularly
- Check Security tab weekly
- Prioritize high severity fixes
- Document false positives

### 2. Tune ZAP Rules
- Add IGNORE rules for false positives
- Adjust severity levels as needed
- Keep rules.tsv updated

### 3. Integrate with Development
- Run baseline scans on all PRs
- Don't merge if high severity found
- Include security in code reviews

### 4. Schedule Deep Scans
- Run full scans weekly or monthly
- Schedule during low-traffic periods
- Review comprehensive reports

### 5. Track Metrics
- Monitor findings over time
- Celebrate security improvements
- Report on security posture

## Troubleshooting

### Scan Fails to Start
- **Check AWS credentials**: Verify secrets are configured
- **Verify staging bucket**: Ensure bucket exists and is accessible
- **Check workflow permissions**: Security-events write permission required

### Too Many False Positives
- **Update .zap/rules.tsv**: Add IGNORE rules for false positives
- **Use baseline scan**: Full scan may be too aggressive
- **Review ZAP documentation**: Understand rule IDs

### Scan Takes Too Long
- **Use baseline instead of full**: Faster for CI/CD
- **Reduce target scope**: Scan fewer pages
- **Schedule full scans**: Run comprehensive scans off-hours

### Results Not in Security Tab
- **Check SARIF upload**: Verify upload-sarif step succeeded
- **Verify permissions**: Ensure security-events: write is set
- **Check file paths**: Ensure SARIF files were generated

## Manual ZAP Scanning

For local testing, you can run ZAP manually:

```bash
# Pull ZAP Docker image
docker pull owasp/zap2docker-stable

# Run baseline scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://robertconsulting.net \
  -r zap-report.html

# Run full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://robertconsulting.net \
  -r zap-report.html
```

## Additional Resources

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [ZAP GitHub Action](https://github.com/zaproxy/action-baseline)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## Support

For issues or questions:
1. Check GitHub Actions logs for error details
2. Review ZAP documentation for rule specifics
3. Update workflow configuration as needed
4. Consult OWASP ZAP community forums

---

**Status**: ✅ **ACTIVE** - OWASP ZAP security scanning is now integrated and running automatically on your repository.

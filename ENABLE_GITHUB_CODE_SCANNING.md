# Enable GitHub Code Scanning for OWASP ZAP Integration

## Overview

To enable SARIF file uploads from OWASP ZAP to the GitHub Security tab, you need to enable the **Code scanning** feature in your repository settings.

## Steps to Enable Code Scanning

### 1. Navigate to Repository Settings
1. Go to your repository on GitHub
2. Click the **Settings** tab
3. In the left sidebar, click **Security**

### 2. Enable Code Scanning
1. In the **Security** section, find **Code scanning**
2. Click **Set up code scanning**
3. You'll see two options:
   - **Set up this workflow** (for CodeQL)
   - **Advanced** (for custom SARIF uploads)

### 3. Choose Advanced Setup
1. Click **Advanced**
2. Select **Upload SARIF file**
3. Click **Set up this workflow**

### 4. Configure the Workflow (Optional)
GitHub will create a basic workflow file. You can:
- Keep the default configuration
- Customize the workflow as needed
- The OWASP ZAP workflow will automatically use this setup

## What This Enables

Once code scanning is enabled:

✅ **SARIF Uploads**: OWASP ZAP can upload security findings to GitHub Security tab
✅ **Security Tab Integration**: View vulnerabilities alongside your code
✅ **Issue Tracking**: Track security issues over time
✅ **Pull Request Integration**: See security findings in PRs
✅ **Alert Management**: Manage and dismiss false positives

## Verification

After enabling code scanning:

1. **Run the OWASP ZAP workflow** (manually or wait for next trigger)
2. **Check the Security tab** for uploaded findings
3. **Verify no upload errors** in the workflow logs

## Expected Workflow Behavior

### Before Enabling Code Scanning:
```
⚠️ SARIF file not found, skipping upload to Security tab
This is normal if the scan failed or code scanning is not enabled
```

### After Enabling Code Scanning:
```
📄 SARIF file found, uploading to GitHub Security tab...
✅ Successfully uploaded SARIF file to GitHub Security tab
```

## Troubleshooting

### "Code scanning is not enabled" Error
- **Solution**: Follow the steps above to enable code scanning
- **Alternative**: The workflow will continue without SARIF uploads

### "Path does not exist: zap-baseline-report.sarif" Error
- **Cause**: ZAP scan failed or didn't generate SARIF file
- **Solution**: Check ZAP scan logs for errors
- **Workaround**: Workflow now handles this gracefully

### No Findings in Security Tab
- **Check**: Ensure ZAP scan completed successfully
- **Verify**: SARIF file was generated and uploaded
- **Wait**: It may take a few minutes for findings to appear

## Benefits of Enabling Code Scanning

1. **Centralized Security View**: All security findings in one place
2. **Integration with Development**: Security findings in PRs and issues
3. **Historical Tracking**: Track security improvements over time
4. **Team Collaboration**: Share security findings with team members
5. **Compliance**: Meet security scanning requirements

## Cost

- **GitHub Code Scanning**: Free for public repositories
- **Private Repositories**: May require GitHub Advanced Security license
- **No Additional Cost**: For the OWASP ZAP integration itself

---

**Next Step**: Enable code scanning using the steps above, then run the OWASP ZAP workflow to see security findings in your GitHub Security tab!

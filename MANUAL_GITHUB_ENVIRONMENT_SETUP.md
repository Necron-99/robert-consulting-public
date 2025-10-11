# Manual GitHub Environment Setup Guide

Since GitHub CLI is not available, here's how to manually set up the production deployment environment in GitHub.

## Step-by-Step Manual Setup

### 1. Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/Necron-99/robert-consulting.net`
2. Click on **Settings** (in the repository navigation bar)
3. In the left sidebar, click on **Environments**

### 2. Create New Environment

1. Click the **New environment** button
2. Enter the environment name: `production-deployment`
3. Click **Configure environment**

### 3. Configure Protection Rules

#### Required Reviewers
1. Check the box for **Required reviewers**
2. Add yourself as a reviewer (search for your username)
3. Set the number of required reviewers to `1`

#### Deployment Branches
1. Check the box for **Restrict deployments to protected branches**
2. This will ensure only the `main` branch can trigger production deployments

#### Environment URL (Optional)
1. In the **Environment URL** field, enter: `https://robertconsulting.net`
2. This helps identify which environment is being deployed to

### 4. Save Configuration

1. Click **Save protection rules**
2. The environment is now configured with manual approval required

## Verification

After setup, you should see:
- Environment name: `production-deployment`
- Protection rules: Required reviewers (1)
- Deployment branches: Protected branches only
- Environment URL: `https://robertconsulting.net`

## Testing the Setup

1. Make a small change to your repository
2. Commit and push to the `main` branch
3. Go to **Actions** tab in your repository
4. You should see the "Staging to Production Deployment Pipeline" workflow running
5. After staging deployment and tests complete, you'll see a manual approval step
6. Click **Review deployments** to approve the production deployment

## Alternative: Use GitHub Web Interface

If you prefer, you can also:

1. Go to **Actions** → **Staging to Production Deployment Pipeline**
2. Click **Run workflow**
3. Use the manual dispatch options:
   - `skip_tests: false` (recommended)
   - `force_production: false` (recommended)

## Troubleshooting

### Environment Not Found
- Make sure the environment name is exactly `production-deployment`
- Check that you're in the correct repository
- Verify you have admin permissions

### Approval Not Working
- Ensure you're added as a required reviewer
- Check that the environment has protection rules enabled
- Verify the workflow is using the correct environment name

### Workflow Not Triggering
- Make sure you're pushing to the `main` branch
- Check that the workflow file is in `.github/workflows/`
- Verify the workflow syntax is correct

## Emergency Deployment

If you need to bypass the approval process:

1. Go to **Actions** → **Legacy Direct Deployment (Deprecated)**
2. Click **Run workflow**
3. Set `emergency_deployment: true`
4. This will deploy directly to production (use with caution)

## Next Steps

Once the environment is set up:

1. **Test the Pipeline**: Make a small change and watch it work
2. **Review Staging**: Always check `https://staging.robertconsulting.net` before approving
3. **Monitor Deployments**: Watch the post-deployment monitoring
4. **Document Issues**: Keep track of any problems for future improvements

## Support

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Verify all environment settings are correct
3. Ensure you have the necessary repository permissions
4. Review the workflow file syntax

---

**Note**: This manual setup provides the same functionality as the automated script, just through the GitHub web interface instead of the command line.

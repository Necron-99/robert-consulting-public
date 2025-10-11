# Manual GitHub Environment Setup Guide (2025)

Since GitHub CLI is not available, here's how to manually set up the production deployment environment in GitHub using the current interface.

## Step-by-Step Manual Setup

### 1. Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/Necron-99/robert-consulting.net`
2. Click on **Settings** (in the repository navigation bar at the top)
3. In the left sidebar, scroll down and click on **Environments**

### 2. Create New Environment

1. Click the **New environment** button (green button in the top right)
2. Enter the environment name: `production-deployment`
3. Click **Configure environment**

### 3. Configure Deployment Protection Rules

#### Required Reviewers
1. In the **Deployment protection rules** section:
   - Check the box for **Required reviewers**
   - Click **Add people or teams**
   - Search for and select your username (Necron-99)
   - Set the number of required reviewers to `1`

#### Deployment Branches (Optional)
1. In the **Deployment branches** section:
   - Select **Selected branches**
   - Choose **main** branch only
   - This ensures only the main branch can trigger production deployments

#### Environment URL (Optional)
1. In the **Environment URL** field, enter: `https://robertconsulting.net`
2. This helps identify which environment is being deployed to

### 4. Save Configuration

1. Click **Save protection rules** (at the bottom of the page)
2. The environment is now configured with manual approval required

## Alternative: If Environments Section is Not Visible

If you don't see the "Environments" section in Settings:

1. **Check Repository Permissions**: You need admin access to the repository
2. **Look for "Secrets and variables"**: Some repositories have environments under this section
3. **Check Organization Settings**: If this is an organization repository, environments might be managed at the org level

## Alternative: Create Environment Through Actions (Recommended)

If the Settings approach doesn't work, the workflow will create the environment automatically:

1. Go to **Actions** tab
2. Click on **Staging to Production Deployment Pipeline**
3. Click **Run workflow**
4. The workflow will create the environment automatically when it first runs
5. You can then configure protection rules in Settings → Environments

## Alternative: Use Manual Approval Action (No Environment Required)

If environments don't work, use the fallback workflow that creates GitHub issues for approval:

### Option 1: Use Fallback Workflow
1. Go to **Actions** tab
2. Click on **Staging to Production Deployment Pipeline (Fallback)**
3. Click **Run workflow**
4. The workflow will:
   - Deploy to staging
   - Run tests
   - Create a GitHub issue for approval
   - Wait for you to comment "APPROVE" on the issue
   - Deploy to production after approval

### Option 2: Manual Approval Process
1. The workflow creates a GitHub issue titled "Production Deployment Approval Required"
2. You'll get notified via email/GitHub notifications
3. Comment on the issue with: **APPROVE**
4. The workflow continues automatically
5. To reject, comment: **REJECT**

This approach doesn't require any environment setup and works with all GitHub account types.

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

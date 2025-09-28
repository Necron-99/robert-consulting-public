# GitHub Repository Setup Guide

This guide will help you set up your GitHub repository for the Robert Consulting website with Terraform and AWS.

## 🚀 Step 1: Create GitHub Repository

1. **Log into GitHub** and navigate to your dashboard
2. **Click "New repository"** (green button)
3. **Repository Details:**
   - Repository name: `robert-consulting-website`
   - Description: `Professional consulting business website with Terraform and AWS`
   - Visibility: Private (recommended for business)
   - ✅ Add a README file
   - ✅ Add .gitignore (choose Node template)
4. **Click "Create repository"**

## 🔧 Step 2: Push Your Code

### Option A: Clone and Push (Recommended)

```bash
# Clone the empty GitHub repository
git clone https://github.com/your-username/robert-consulting-website.git
cd robert-consulting-website

# Copy all the project files you've created into this directory
# (All the files from this project should be copied here)

# Add all files to git
git add .

# Commit the initial setup
git commit -m "Initial setup: Consulting website with Terraform and AWS"

# Push to GitHub
git push origin main
```

### Option B: Upload Files via GitHub Web Interface

1. Go to your GitHub repository
2. Click "uploading an existing file" or "Add file" → "Upload files"
3. Drag and drop all your project files
4. Commit the changes

## 🔐 Step 3: Configure GitHub Secrets

1. **Navigate to your repository** → Settings → Secrets and variables → Actions
2. **Click "New repository secret"** and add:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `your-access-key` | AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | `your-secret-key` | AWS secret access key |

**Security Notes:**
- ✅ These secrets are encrypted and only accessible to GitHub Actions
- ✅ They are not visible in logs or to repository collaborators
- ✅ You can update them anytime in the repository settings

## 🏗️ Step 4: AWS Setup

### Create AWS IAM User

1. **Go to AWS IAM Console**
2. **Create User:**
   - Username: `github-actions-user`
   - Access type: Programmatic access
3. **Attach Policies:**
   - `AmazonS3FullAccess`
   - `CloudFrontFullAccess`
   - `Route53FullAccess` (if using custom domain)
4. **Save the credentials** for GitHub secrets

### Configure AWS CLI (Local Development)

```bash
# Install AWS CLI if not already installed
# Configure with your credentials
aws configure
```

## 🚀 Step 5: First Deployment

### Manual Terraform Setup (First Time)

```bash
# Navigate to terraform directory
cd terraform

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan

# Apply the infrastructure
terraform apply
```

### Enable GitHub Actions

1. **Go to your repository** → Actions tab
2. **The workflow should automatically start** when you push code
3. **Monitor the workflow** for any issues

### Workflow Stages:

1. **Validate**: Checks Terraform syntax and formatting
2. **Plan**: Creates infrastructure plan (runs on PRs and pushes)
3. **Apply**: Deploys infrastructure (only on main branch pushes)
4. **Deploy**: Uploads website files to S3 and invalidates CloudFront

## 🌐 Step 6: Custom Domain (Optional)

### If you have a domain:

1. **Uncomment Route 53 resources** in `terraform/main.tf`
2. **Update variables** in `terraform.tfvars`:
   ```hcl
   domain_name = "your-domain.com"
   ```
3. **Re-run Terraform apply**
4. **Update DNS** at your domain registrar

## 📊 Step 7: Monitoring and Maintenance

### View Your Website:
- **CloudFront URL**: Check the Actions workflow output or Terraform outputs
- **S3 URL**: `http://your-bucket-name.s3-website-us-east-1.amazonaws.com`

### Monitor Workflows:
- **Actions Tab**: View all workflow runs
- **Workflow Status**: Green checkmarks indicate success
- **Logs**: Click on any job to see detailed logs

### Monitor Costs:
- **AWS Cost Explorer**
- **CloudWatch Billing Alerts**

### Regular Maintenance:
- **Update dependencies** in Terraform
- **Monitor CloudFront cache**
- **Review AWS costs monthly**

## 🛠️ Troubleshooting

### Common Issues:

1. **Workflow Fails on Apply Stage:**
   - Check AWS credentials in GitHub secrets
   - Verify AWS permissions
   - Check Terraform state

2. **Website Not Loading:**
   - Verify S3 bucket policy
   - Check CloudFront distribution status
   - Clear browser cache

3. **Terraform State Issues:**
   - Check if state file exists
   - Verify backend configuration
   - Consider state migration

4. **GitHub Actions Not Running:**
   - Check if Actions are enabled in repository settings
   - Verify the workflow file is in `.github/workflows/`
   - Check if the repository has the correct permissions

### Getting Help:

- **GitHub Actions Documentation**: [docs.github.com/actions](https://docs.github.com/actions)
- **Terraform AWS Provider**: [registry.terraform.io](https://registry.terraform.io/providers/hashicorp/aws)
- **AWS Documentation**: [docs.aws.amazon.com](https://docs.aws.amazon.com)

## 🎉 Success!

Once everything is set up, you should have:

- ✅ Professional consulting website
- ✅ Automated CI/CD pipeline with GitHub Actions
- ✅ AWS infrastructure managed by Terraform
- ✅ Global CDN with CloudFront
- ✅ Scalable and secure hosting

Your website will be automatically updated whenever you push changes to the main branch!

## 🔄 Workflow Details

### Trigger Events:
- **Push to main**: Full deployment (validate → plan → apply → deploy)
- **Pull Request**: Validation and planning only
- **Manual**: Can be triggered manually from Actions tab

### Security Features:
- **Secrets encryption**: All sensitive data is encrypted
- **Least privilege**: IAM user has minimal required permissions
- **Audit trail**: All actions are logged in GitHub

### Performance Features:
- **Parallel jobs**: Multiple jobs run simultaneously when possible
- **Caching**: Terraform state and dependencies are cached
- **Artifacts**: Terraform plans are stored as artifacts

---

**Next Steps:**
- Customize the website content in the `website/` directory
- Add your actual contact information
- Consider adding a custom domain
- Set up monitoring and analytics
- Configure branch protection rules for production safety
